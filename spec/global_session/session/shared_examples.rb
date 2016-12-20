require 'jwt'

require 'spec_helper'

# Depends on the following `let`s:
#     key_generation_parameter: one of [1024, 2048, 'prime256v1']
#     signature_method: one of [:dsa_sign_asn1, :sign]
#     approximate_token_size: Integer byte size of tokens
shared_examples_for 'all subclasses of Session::Abstract' do
  include SpecHelper

  before do
    @key_factory = KeyFactory.new
    @key_factory.create('authority1', true, parameter:key_generation_parameter)
    @key_factory.create('authority2', false, parameter:key_generation_parameter)
  end

  after do
    @key_factory.destroy
  end

  before(:each) do
    mock_config('common/attributes/signed', ['user'])
    mock_config('common/attributes/insecure', ['favorite_color'])
    mock_config('test/timeout', '60')
  end

  after(:each) do
    reset_mock_config
  end

  context '#initialize' do
    before(:each) do
      mock_config('test/trust', ['authority1'])
      mock_config('test/authority', 'authority1')
      @directory        = GlobalSession::Directory.new(mock_config, @key_factory.dir)
      @original_session = subject.new(@directory)
      @cookie           = @original_session.to_s
    end

    context 'when everything is copacetic' do
      it 'succeeds' do
        expect(subject.new(@directory, @cookie)).to be_kind_of(GlobalSession::Session::Abstract)
      end
    end

    context 'when an insecure attribute changes' do
      before do
        @cookie = tamper_with_insecure_attributes(subject, @cookie, {'favorite_color' => 'blue'})
      end
      it 'succeeds' do
        expect(subject.new(@directory, @cookie)).to be_a(GlobalSession::Session::Abstract)
      end
    end

    context 'when a secure attribute is tampered with' do
      before do
        @cookie = tamper_with_signed_attributes(subject, @cookie, {'evil_haxor' => 'mwahaha'})
      end
      it 'raises InvalidSignature' do
        expect {
          subject.new(@directory, @cookie)
        }.to raise_error(GlobalSession::InvalidSignature)
      end
    end

    context 'when the signer is not trusted' do
      before do
        mock_config('test/trust', ['authority1'])
        mock_config('test/authority', 'authority1')
        @directory2 = GlobalSession::Directory.new(mock_config, @key_factory.dir)
        @cookie = subject.new(@directory2).to_s
        mock_config('test/trust', ['authority2'])
        mock_config('test/authority', nil)
      end
      it 'raises InvalidSignature' do
        expect {
          subject.new(@directory, @cookie)
        }.to raise_error(GlobalSession::InvalidSignature)
      end
    end

    context 'when the session is expired' do
      before do
        fake_now = Time.at(Time.now.to_i + 3_600*2)
        flexmock(Time).should_receive(:now).and_return(fake_now)
      end
      it 'raises ExpiredSession' do
        expect {
          subject.new(@directory, @cookie)
        }.to raise_error(GlobalSession::ExpiredSession)
      end
    end

    context 'when an empty cookie is supplied' do
      it 'creates a new valid session' do
        expect(subject.new(@directory, '').valid?).to eq(true)
      end

      context 'and there is no local authority' do
        before(:each) do
          flexmock(@directory).should_receive(:local_authority_name).and_return(nil)
          flexmock(@directory).should_receive(:private_key).and_return(nil)
        end

        it 'creates a new invalid session' do
          expect(subject.new(@directory, '').valid?).to eq(false)
        end
      end
    end

    context 'when malformed cookies are supplied' do
      bad_cookies = [ '#$(%*#@%^&#!($%*#', rand(2**256).to_s(16) ]

      bad_cookies.each do |cookie|
        it 'copes' do
          expect {
            subject.new(@directory, cookie)
          }.to raise_error(GlobalSession::MalformedCookie)
        end
      end
    end
  end

  context 'given a valid session' do
    before(:each) do
      mock_config('test/trust', ['authority1'])
      mock_config('test/authority', 'authority1')
      @directory = GlobalSession::Directory.new(mock_config, @key_factory.dir)
      @session   = subject.new(@directory)
    end

    context '#renew!' do
      it 'updates created_at' do
        old = @session.created_at
        future_time = Time.at(Time.now.to_i + 5)
        flexmock(Time).should_receive(:now).and_return future_time
        @session.renew!
        expect(@session.created_at).not_to eq(old)
      end

      it 'updates expired_at' do
        old = @session.expired_at
        future_time = Time.at(Time.now.to_i + 5)
        flexmock(Time).should_receive(:now).and_return future_time
        @session.renew!
        expect(@session.expired_at).not_to eq(old)
      end
    end

    context '#new_record?' do
      it 'returns true when the session was just created' do
        expect(@session.new_record?).to eq(true)
      end

      it 'returns false when the session was loaded from a cookie' do
        loaded_session = subject.new(@directory, @session.to_s)
        expect(loaded_session.new_record?).to eq(false)
      end
    end

    context '#delete' do
      context 'when the key is insecure' do
        before(:each) do
          @session['favorite_color'] = 'bar'
        end

        it 'removes the key from the session' do
          @session.delete('favorite_color')
          expect(@session['favorite_color']).to eq(nil)
        end
      end

      context 'when the key is signed' do
        before(:each) do
          @session['user'] = 'bar'
        end

        it 'removes the key from the session' do
          @session.delete('user')
          expect(@session['user']).to eq(nil)
        end
      end

      context 'when the key does not exist in the session' do
        it 'raises ArgumentError' do
          expect {
            @session.delete('foo')
          }.to raise_error(ArgumentError)
        end
      end
    end

    context 'given a valid session received over the network' do
      let(:cookie) { @session.to_s }

      before do
        # force signature + reload + non-new-record
        @session = subject.new(@directory, cookie)
      end

      context '#dirty?' do
        it 'returns true when secure attributes change' do
          expect(@session.dirty?).to eq(false)
          @session['user'] = rand(2**32-1)
          expect(@session.dirty?).to eq(true)
        end

        it 'returns true when insecure attributes change' do
          expect(@session.dirty?).to eq(false)
          @session['favorite_color'] = 'thistle'
          expect(@session.dirty?).to eq(true)
        end
      end

      context '#to_s' do
        it 'produces a reasonably sized token' do
          expect(@session.to_s.size).to be_within(approximate_token_size * 0.10).of(approximate_token_size)
        end

        it 'reuses signature when nothing has changed' do
          expect(@session.to_s).to eq(cookie)
        end

        it 'reuses signature when insecure attributes change' do
          @session['favorite_color'] = 'mauve'
          expect(@session.to_s).not_to eq(cookie)
        end

        it 'computes signature when timestamps change' do
          before = @session.to_s
          sleep(1) # ensure timestamp will change
          @session.renew!
          after = @session.to_s
          expect(before).not_to eq(after)
        end

        it 'computes signature when secure secure attributes change' do
          @session['user'] = rand(2**32-1)
          expect(@session.to_s).not_to eq(cookie)
        end
      end

      context '#clone' do
        before(:each) do
          @session['user'] = 'bar'
        end

        it 'is not destructive to the original session' do
          new_session = @session.clone
          new_session.delete('user')
          expect(@session['user']).to eq('bar')
        end
      end
    end
  end
end

# Depends on the following `let`s:
#     algorithm_identifier: ES256, RSA256, etc
#     key_generation_parameter: one of [1024, 2048, 'prime256v1']
#     ... TODO ...
shared_examples_for 'JWT compatible subclasses of Session::Abstract' do
  include SpecHelper

  let(:trusted_issuer) { "my-#{algorithm_identifier}" }

  let(:key_factory) { KeyFactory.new }
  before do
    key_factory.create(trusted_issuer, true, parameter:key_generation_parameter)
    key_factory.create('untrusted', true, parameter:key_generation_parameter)
    FileUtils.rm(File.join(key_factory.dir, 'untrusted.pub'))
  end
  after do
    key_factory.destroy
  end

  let(:configuration) do
    {
      'attributes' => {
        'signed' => ['sub']
      },
      'keystore' => {
        'public' => key_factory.dir,
        'private' => File.join(key_factory.dir, "#{trusted_issuer}.key"),
      },
      'timeout' => 60,
    }
  end

  let(:directory) { GlobalSession::Directory.new(configuration) }

  let(:trusted_public_key) do
    directory.keystore.public_keys[trusted_issuer]
  end

  let(:trusted_private_key) do
    directory.keystore.private_key
  end

  let(:untrusted_private_key) do
    OpenSSL::PKey.read(File.read(File.join(key_factory.dir, 'untrusted.key')))
  end

  context '#initialize' do
    let(:now) { Time.now }
    let(:expire_at) { now + 60 }

    let(:jwt_payload) do
      {
        'iat' => now.to_i,
        'exp' => expire_at.to_i,
        'iss' => trusted_public_key,
      }
    end

    let(:valid_jwt) do
      data = {'iss' => trusted_issuer, 'sub' => 'jwt joe'}
      JWT.encode(jwt_payload.merge(data),
                 trusted_private_key,
                 algorithm_identifier)
    end

    let(:expired_jwt) do
      data = {'iss' => trusted_issuer, 'sub' => 'jwt joe', 'exp' => Integer(now - 300)}
      JWT.encode(jwt_payload.merge(data),
                 trusted_private_key,
                 algorithm_identifier)
    end


    let(:premature_jwt) do
      data = {'iss' => trusted_issuer, 'sub' => 'jwt joe', 'nbf' => Integer(now + 10)}
      JWT.encode(jwt_payload.merge(data),
                 trusted_private_key,
                 algorithm_identifier)
    end

    let(:forged_jwt) do
      data = {'iss' => trusted_issuer, 'sub' => 'jwt joe'}
      JWT.encode(jwt_payload.merge(data),
                 untrusted_private_key,
                 algorithm_identifier)
    end

    let(:untrusted_jwt) do
      data = {'iss' => 'untrusted', 'sub' => 'jwt joe'}
      JWT.encode(jwt_payload.merge(data),
                 untrusted_private_key,
                 algorithm_identifier)
    end

    it 'accepts valid JWTs with suitable issuer' do
      session = subject.new(directory, valid_jwt)
      expect(session['sub']).to eq('jwt joe')
      expect(session.created_at).to be_within(1).of(now)
      expect(session.expired_at).to be_within(1).of(expire_at)
    end

    it 'rejects expired JWTs' do
      expect {
        subject.new(directory, expired_jwt)
      }.to raise_error(GlobalSession::ExpiredSession)
    end

    it 'rejects not-yet-valid JWTs' do
      expect {
        subject.new(directory, premature_jwt)
      }.to raise_error(GlobalSession::PrematureSession)
    end

    it 'rejects JWTs with unknown issuer' do
      expect {
        subject.new(directory, forged_jwt)
      }.to raise_error(GlobalSession::InvalidSignature)
    end

    it 'rejects JWTs with unknown issuer' do
      expect {
        subject.new(directory, untrusted_jwt)
      }.to raise_error(GlobalSession::InvalidSignature)
    end
  end

  context '#to_s' do
    it 'returns a valid, signed JWT' do
      session = subject.new(directory)
      session['sub'] = 'joe schmoe'

      payload, header = JWT.decode(session.to_s, trusted_public_key)
      expect(header).to eq({'typ'=>'JWT', 'alg'=>algorithm_identifier})
      expect(payload['sub']).to eq(session['sub'])
      expect(payload['iat']).to eq(session.created_at.to_i)
      expect(payload['exp']).to eq(session.expired_at.to_i)
    end
  end
end
