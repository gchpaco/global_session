require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe GlobalSession::Rails::ActionControllerInstanceMethods do
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
    mock_config('test/cookie/name', 'global_session_cookie')
    mock_config('test/cookie/domain', 'localhost')
    mock_config('test/trust', ['authority1'])
    mock_config('test/authority', 'authority1')

    GlobalSession::Rails.configuration = mock_config
    GlobalSession::Rails.directory = GlobalSession::Directory.new(mock_config, @keystore.dir)
    @directory        = GlobalSession::Rails.directory
    @original_session = GlobalSession::Session.new(@directory)
    @cookie           = @original_session.to_s

    @klass = Class.new(StubController) do
      has_global_session
    end

    @controller = @klass.new( {'global_session'=>@original_session}, 
                                      {'global_session_cookie'=>@cookie} )
    flexmock(@controller).should_receive(:global_session_create_directory).and_return(@directory)
  end

  after(:each) do
    @keystore.reset
    reset_mock_config
  end

  context :global_session_initialize do
    context 'when an exception is raised' do
      before(:each) do
        @controller.request.env['global_session.error'] = GlobalSession::ExpiredSession.new("moo!")        
      end

      it 'should create a new session, update the cookie, and re-raise' do
        lambda {
          @controller.global_session_initialize
        }.should raise_error(GlobalSession::ExpiredSession)
      end
    end

    context 'with global_session_options[:enabled] == false' do
      it 'should skip initialization and tell the middleware not to do anything'
    end

    context 'with global_session_options[:renew] == false' do
      it 'should tell the middleware not to renew the cookie'
    end

    context 'with global_session_options[:renew] == false' do
      it 'should tell the middleware not to renew the cookie'
    end
  end
end
