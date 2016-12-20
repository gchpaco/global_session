require File.expand_path(File.join(File.dirname(__FILE__), '..' , 'spec_helper'))

describe GlobalSession::Directory do
  include SpecHelper

  before(:all) do
    @key_factory = KeyFactory.new
  end

  after(:all) do
    @key_factory.destroy
  end

  before(:each) do
    mock_config('test/timeout', 60)
    mock_config('test/cookie/name', 'session')
    mock_config('test/cookie/domain', 'example.com')
    mock_config('test/attributes/signed', ['user'])
    mock_config('test/attributes/insecure', ['favorite_color'])
  end

  after(:each) do
    @key_factory.reset
    reset_mock_config
  end

  context :initialize do
    context 'given a configuration that specifies a local authority' do
      before(:each) do
        @authority_name = "authority#{rand(2**16)}"
        mock_config('test/authority', @authority_name)
      end

      context 'and a keystore with no private keys' do
        it 'raises ConfigurationError' do
          @key_factory.create(@authority_name, false)
          expect {
            GlobalSession::Directory.new(mock_config, @key_factory.dir)
          }.to raise_error(GlobalSession::ConfigurationError)
        end
      end

      context 'and a keystore with an incorrectly-named private key' do
        it 'raises ConfigurationError' do
          @key_factory.create('wrong_name', true)
          expect {
            $tony = true
            GlobalSession::Directory.new(mock_config, @key_factory.dir)
          }.to raise_error(GlobalSession::ConfigurationError)
        end
      end

      context 'and a keystore with a correctly-named private key' do
        it 'succeeds' do
          @key_factory.create(@authority_name, true)
          GlobalSession::Directory.new(mock_config, @key_factory.dir)
        end
      end
    end
  end

  context :create_session do
    CURRENT_MAJOR = Integer(GlobalSession::VERSION.split('.').first)

    before(:each) do
      @authority_name = "authority#{rand(2**16)}"
      mock_config('test/authority', @authority_name)
      @key_factory.create(@authority_name, true)
      @directory = GlobalSession::Directory.new(mock_config, @key_factory.dir)
    end

    context 'given a configuration that does not specify cookie/version' do
      klass_name = "V#{CURRENT_MAJOR}"
      let(:klass) { GlobalSession::Session.const_get(klass_name.to_sym) }
      it "creates a #{klass_name} session" do
        expect(@directory.create_session).to be_a(klass)
      end
    end

    (1..CURRENT_MAJOR).each do |v|
      context "given a configuration that contains cookie/version=#{v}" do
        klass_name = "V#{v}"
        before(:each) do
          mock_config('test/cookie/version', v)
        end
        let(:klass) { GlobalSession::Session.const_get(klass_name.to_sym) }
        it "creates a #{klass_name} session" do
          expect(@directory.create_session).to be_a(klass)
        end
      end
    end
  end
end
