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

    context 'when everything is copacetic' do
      it 'should succeed' do
        GlobalSession::Session.new(@directory, @cookie).should be_a(GlobalSession::Session::Abstract)
      end
    end

    context 'when a trusted signature is passed in' do
      it 'should not recompute the signature' do
        flexmock(@directory.authorities['authority1']).should_receive(:public_decrypt).never
        valid_digest = @original_session.signature_digest
        GlobalSession::Session.new(@directory, @cookie, valid_digest).should be_a(GlobalSession::Session::Abstract)
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
        GlobalSession::Session.new(@directory, @cookie).should be_a(GlobalSession::Session::Abstract)
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

    context :to_hash do
      before(:each) do
        @hash = @session.to_hash
      end

      it 'includes metadata' do
        @hash[:metadata][:id].should == @session.id
        @hash[:metadata][:created_at].should == @session.created_at
        @hash[:metadata][:expired_at].should == @session.expired_at
        @hash[:metadata][:authority].should == @session.authority
        @hash[:signed].each_pair { |k,v| @session[k].should == v }
        @hash[:insecure].each_pair { |k,v| @session[k].should == v }
      end
    end

    context :new_record? do
      it 'should return true when the session was just created' do
        @session.new_record?.should be_true
      end

      it 'should return false when the session was loaded from a cookie' do
        loaded_session = GlobalSession::Session.new(@directory, @session.to_s)
        loaded_session.new_record?.should be_false
      end
    end
  end

  context 'when generating a UUID' do
    it 'choose have at least 50% unpredictable characters' do
      uuids = []
      pos_to_freq = {}

      1_000.times do
        uuid = RightSupport::Data::UUID.generate
        uuid.gsub!(/[^0-9a-fA-F]/, '')
        uuids << uuid
      end

      uuids.each do |uuid|
        pos = 0
        uuid.each_char do |char|
          pos_to_freq[pos] ||= {}
          pos_to_freq[pos][char] ||= 0
          pos_to_freq[pos][char] += 1
          pos += 1
        end
      end

      predictable_pos = 0
      total_pos       = 0

      pos_to_freq.each_pair do |pos, frequencies|
        n    = frequencies.size.to_f
        total  = frequencies.values.inject(0) { |x, v| x+v }.to_f
        mean = total / n

        sum_diff_sq = 0.0
        frequencies.each_pair do |char, count|
          sum_diff_sq += (count - mean)**2
        end
        var = (1 / n) * sum_diff_sq
        std_dev = Math.sqrt(var)

        predictable_pos += 1 if std_dev == 0.0
        total_pos += 1
      end

      # Less than half of the character positions should be predictable
      (predictable_pos.to_f / total_pos.to_f).should <= 0.5
    end
  end
end