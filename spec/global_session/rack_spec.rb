require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

require 'global_session/rack'
require 'tempfile'

describe GlobalSession::Rack::Middleware do
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
    @config = Tempfile.new("config")
    @config << <<EOS
common:
  attributes:
    signed: [user]
    insecure: [favorite_color]
  timeout: 60
  cookie:
    name: global_session_cookie
  trust: [authority1]
  authority: authority1
EOS
    @config.close
  end

  after(:each) do
    @config.close(true)
    @keystore.reset
  end

  context :initialization do
    it 'can initialize from files' do
      @null_app = flexmock('Rack App')
      @null_app.should_receive(:call).once.by_default
      @app = GlobalSession::Rack::Middleware.new(@null_app, @config.path, @keystore.dir)
      @app.call({})
    end
  end
end

describe GlobalSession::Rack::Middleware do
  include SpecHelper

  before(:all) do
    @keystore = KeyFactory.new
    @keystore.create('authority1', true)
    @keystore.create('authority2', false)
    mock_config('common/attributes/signed', ['user'])
    mock_config('common/attributes/insecure', ['favorite_color'])
    mock_config('test/timeout', '60')
    mock_config('test/cookie/name', 'global_session_cookie')
    mock_config('test/trust', ['authority1'])
    mock_config('test/authority', 'authority1')
  end

  after(:all) do
    @keystore.destroy
  end

  before(:each) do
    @config    = mock_config
    @directory = GlobalSession::Directory.new(@config, @keystore.dir)
    @null_app = flexmock('Rack App')
    @null_app.should_receive(:call).once.by_default
    @app = GlobalSession::Rack::Middleware.new(@null_app, @config, @directory)
    @env = {'rack.cookies' => {}}
  end

  after(:each) do
    @keystore.reset
    reset_mock_config
  end

  context :renew_cookie do
    context 'when session is not expiring soon' do
      before(:each) do
        mock_config('test/renew', '15')
        @original_session = GlobalSession::Session.new(@directory)
        @cookie = @original_session.to_s
        @env['rack.cookies']['global_session_cookie'] = @cookie
      end

      it 'should not renew the cookie' do
        @app.call(@env)
        @env.should have_key('global_session')
        @env['global_session'].to_s.should == @cookie
      end
    end

    context 'when session is about to expire' do
      before(:each) do
        @original_session = GlobalSession::Session.new(@directory)
        @original_session.renew!(Time.at(Time.now.to_i + 15))
        @cookie = @original_session.to_s
        @env['rack.cookies']['global_session_cookie'] = @cookie
      end

      it 'should auto-renew the cookie if requested' do
        mock_config('test/renew', '15')
        @app.call(@env)
        @env.should have_key('global_session')
        @env['global_session'].to_s.should_not == @cookie
      end

      context 'when the app disables renewal' do
        before(:each) do
          @env['global_session.req.renew'] = false
        end

        it 'should not update the cookie' do
          flexmock(@env['rack_cookies']).should_receive(:[]=).never
          @app.call(@env)
        end
      end
    end
  end

  context :update_cookie do
    before(:each) do
      @env['SERVER_NAME'] = 'baz.foobar.com'
    end

    it 'should use the server name associated with the HTTP request' do
      flexmock(@env['rack_cookies']).should_receive(:[]=).with('global_session_cookie', {:value=>String, :domain=>'baz.foobar.com', :expires=>Time})
      @app.call(@env)
    end

    context 'when the configuration specifies a cookie domain' do
      before(:each) do
        mock_config('test/cookie/domain', 'foobar.com')
      end

      it 'should set cookies with the domain specified in the configuration' do
        flexmock(@env['rack_cookies']).should_receive(:[]=).with('global_session_cookie', {:value=>String, :domain=>'foobar.com', :expires=>Time})
        @app.call(@env)
      end
    end

    context 'when the app disables updates' do
      before(:each) do
        @env['global_session.req.update'] = false
      end

      it 'should not update the cookie' do
        flexmock(@env['rack_cookies']).should_receive(:[]=).never
        @app.call(@env)
      end
    end
  end

  context :read_cookie do
    context 'with no cookie' do
      it 'should populate env with a new session' do
        @app.call(@env)
        @env.should have_key('global_session')
      end
    end

    context 'with a valid cookie' do
      before(:each) do
        @original_session = GlobalSession::Session.new(@directory)
        @cookie = @original_session.to_s
        @env['rack.cookies']['global_session_cookie'] = @cookie
      end

      it 'should populate env with a session object' do
        @app.call(@env)
        @env.should have_key('global_session')
        @env['global_session'].to_s.should == @cookie
      end
    end

    context 'with errors' do
      before(:each) do
        @cookie_name = @config['cookie']['name']
        @env['rack.cookies'][@cookie_name] = 'Not a real cookie. A mock protects me from being used.'
        @fresh_session = GlobalSession::Session.new(@directory)
      end

      it 'should swallow client errors' do
        flexmock(GlobalSession::Session).should_receive(:new).once.and_raise(GlobalSession::ClientError)
        flexmock(GlobalSession::Session).should_receive(:new).with(@directory).and_return(@fresh_session)
        @app.call(@env)
        @env.should have_key('global_session')
        @env.should have_key('global_session.error')
        @env['global_session.error'].should be_a(GlobalSession::ClientError)
      end

      it 'should swallow configuration errors' do
        flexmock(GlobalSession::Session).should_receive(:new).once.and_raise(GlobalSession::ConfigurationError)
        flexmock(GlobalSession::Session).should_receive(:new).with(@directory).and_return(@fresh_session)
        @app.call(@env)
        @env.should have_key('global_session')
        @env.should have_key('global_session.error')
        @env['global_session.error'].should be_a(GlobalSession::ConfigurationError)
      end

      it 'should raise other errors' do
        flexmock(GlobalSession::Session).should_receive(:new).once.and_raise(StandardError)
        flexmock(GlobalSession::Session).should_receive(:new).with(@directory).and_return(@fresh_session)
        @null_app.should_receive(:call).never
        lambda { @app.call(@env) }.should raise_error(StandardError)
      end
    end
  end
end
