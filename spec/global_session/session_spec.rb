require File.expand_path(File.join(File.dirname(__FILE__), '..' , 'spec_helper'))

describe GlobalSession::Session do
  include SpecHelper

  before(:all) do
    @keystore = KeyFactory.new
    @keystore.create('authority1', true)
    @keystore.create('authority2', false)
  end

  after(:all) do
    @keystore.destroy
  end

  before(:each) do
    mock_config('common/attributes/signed', ['user'])
    mock_config('common/attributes/insecure', ['favorite_color'])
    mock_config('test/timeout', '60')
  end

  after(:each) do
    @keystore.reset
    reset_mock_config
  end

  context :load_from_cookie do
    before(:each) do
      mock_config('test/trust', ['authority1'])
      mock_config('test/authority', 'authority1')
      @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
      @original_session = GlobalSession::Session.new(@directory)
      @cookie           = @original_session.to_s
    end

    context 'when everything is copascetic' do
      it 'should succeed' do
        GlobalSession::Session.should === GlobalSession::Session.new(@directory, @cookie)
      end
    end

    context 'when a trusted signature is passed in' do
      it 'should not recompute the signature' do
        flexmock(@directory.authorities['authority1']).should_receive(:public_decrypt).never
        valid_digest = @original_session.signature_digest
        GlobalSession::Session.should === GlobalSession::Session.new(@directory, @cookie, valid_digest)
      end
    end

    context 'when an insecure attribute has changed' do
      before do
        zbin = GlobalSession::Encoding::Base64Cookie.load(@cookie)
        json = Zlib::Inflate.inflate(zbin)
        hash = GlobalSession::Encoding::JSON.load(json)
        hash['dx'] = {'favorite_color' => 'blue'}
        json = GlobalSession::Encoding::JSON.dump(hash)
        zbin = Zlib::Deflate.deflate(json, Zlib::BEST_COMPRESSION)
        @cookie = GlobalSession::Encoding::Base64Cookie.dump(zbin)        
      end
      it 'should succeed' do
        GlobalSession::Session.should === GlobalSession::Session.new(@directory, @cookie)
      end
    end

    context 'when a secure attribute has been tampered with' do
      before do
        zbin = GlobalSession::Encoding::Base64Cookie.load(@cookie)
        json = Zlib::Inflate.inflate(zbin)
        hash = GlobalSession::Encoding::JSON.load(json)
        hash['ds'] = {'evil_haxor' => 'mwahaha'}
        json = GlobalSession::Encoding::JSON.dump(hash)
        zbin = Zlib::Deflate.deflate(json, Zlib::BEST_COMPRESSION)
        @cookie = GlobalSession::Encoding::Base64Cookie.dump(zbin)        
      end
      it 'should raise SecurityError' do
        lambda {
          GlobalSession::Session.new(@directory, @cookie)
        }.should raise_error(SecurityError)
      end
    end

    context 'when the signer is not trusted' do
      before do
        mock_config('test/trust', ['authority1'])
        mock_config('test/authority', 'authority1')
        @directory2 = GlobalSession::Directory.new(mock_config, @keystore.dir)
        @cookie = GlobalSession::Session.new(@directory2).to_s
        mock_config('test/trust', ['authority2'])
        mock_config('test/authority', nil)        
      end
      it 'should raise SecurityError' do
        lambda {
          GlobalSession::Session.new(@directory, @cookie)
        }.should raise_error(SecurityError)
      end
    end

    context 'when the session is expired' do
      before do
        fake_now = Time.at(Time.now.to_i + 3600)
        flexmock(Time).should_receive(:now).and_return(fake_now)        
      end
      it 'should raise ExpiredSession' do
        lambda {
          GlobalSession::Session.new(@directory, @cookie)
        }.should raise_error(GlobalSession::ExpiredSession)
      end
    end

    context 'when an empty cookie is supplied' do
      it 'should create a new valid session' do
        GlobalSession::Session.new(@directory, '').valid?.should be_true
      end

      context 'and there is no local authority' do
        before(:each) do
          flexmock(@directory).should_receive(:local_authority_name).and_return(nil)
          flexmock(@directory).should_receive(:private_key).and_return(nil)
        end

        it 'should create a new invalid session' do
          GlobalSession::Session.new(@directory, '').valid?.should be_false
        end
      end
    end

    context 'when malformed cookies are supplied' do
      bad_cookies = [ '#$(%*#@%^&#!($%*#', rand(2**256).to_s(16) ]

      bad_cookies.each do |cookie|
        it 'should cope' do
          lambda {
            GlobalSession::Session.new(@directory, cookie)
          }.should raise_error(GlobalSession::MalformedCookie)
        end
      end
    end
  end

  context 'given a valid session' do
    before(:each) do
      mock_config('test/trust', ['authority1'])
      mock_config('test/authority', 'authority1')
      @directory = GlobalSession::Directory.new(mock_config, @keystore.dir)
      @session   = GlobalSession::Session.new(@directory)
    end

    context :renew! do
      it 'updates created_at' do
        old = @session.created_at
        future_time = Time.at(Time.now.to_i + 5)
        flexmock(Time).should_receive(:now).and_return future_time
        @session.renew!
        @session.created_at.should_not == old
      end

      it 'updates expired_at' do
        old = @session.expired_at
        future_time = Time.at(Time.now.to_i + 5)
        flexmock(Time).should_receive(:now).and_return future_time
        @session.renew!
        @session.expired_at.should_not == old
      end
    end
  end
end