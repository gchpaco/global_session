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

    ActionController::Base.global_session_config = mock_config

    @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
    @original_session = GlobalSession::Session.new(@directory)
    @cookie           = @original_session.to_s

    @klass = Class.new(StubController) do
      has_global_session :integrated=>true
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
  end

  context :global_session_skip_update do
    it 'should set the appropriate Rack env' do
      @controller.global_session_skip_update
      @controller.request.env['global_session.req.update'].should be_false
    end
  end

  context :global_session_skip_renew do
    it 'should set the appropriate Rack env' do
      @controller.global_session_skip_renew
      @controller.request.env['global_session.req.renew'].should be_false
    end
  end

  context :session_with_global_session do
    context 'when no global session has been instantiated yet' do
      before(:each) do
        @controller.global_session.should be_nil
      end

      it 'should return the Rails session' do
        flexmock(@controller).should_receive(:session_without_global_session).and_return('local session')
        @controller.session.should == 'local session'
      end
    end
    context 'when a global session has been instantiated' do
      before(:each) do
        @controller.global_session_initialize
      end

      it 'should return an integrated session' do
        GlobalSession::IntegratedSession.should === @controller.session
      end
    end
    context 'when the global session has been reset' do
      before(:each) do
        @controller.global_session_initialize
        @old_integrated_session = @controller.session
        GlobalSession::IntegratedSession.should === @old_integrated_session
        @controller.instance_variable_set(:@global_session, 'new global session')
      end

      it 'should return a fresh integrated session' do
        @controller.session.should_not == @old_integrated_session
      end
    end
    context 'when the local session has been reset' do
      before(:each) do
        @controller.global_session_initialize
        @old_integrated_session = @controller.session
        GlobalSession::IntegratedSession.should === @old_integrated_session
        @controller.request.session = 'new local session'
      end

      it 'should return a fresh integrated session' do
        @controller.request.session.should_not == @old_integrated_session
      end
    end
  end
end
