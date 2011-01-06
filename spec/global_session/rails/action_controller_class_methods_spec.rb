require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe GlobalSession::Rails::ActionControllerClassMethods do
  include SpecHelper

  before(:each) do
    @klass = Class.new(StubController)
    @env   = {'global_session' => flexmock('global session')}
  end

  context :no_global_session do
    context 'when has_global_session was never called' do
      it 'should no-op' do
        @klass.no_global_session
      end
    end

    context 'when has_global_session was called' do
      it 'should disarm the filters' do
        @klass.has_global_session
        @klass.no_global_session

        @controller = @klass.new( {}, {}, {}, {:action=>:index} )
        @controller.process({})
        @controller.global_session.should be_nil
      end
    end
  end

  context :has_global_session do
    it 'should enable the global session' do
      @klass.has_global_session
      @controller = @klass.new( @env, {}, {}, {:action=>:index} )
      @controller.process({})
      @controller.global_session.should_not be_nil

      @controller2 = @klass.new( {}, {}, {}, {:action=>:show} )
      @controller2.process({})
      @controller.global_session.should_not be_nil
    end

    it 'should use sensible defaults' do
      @klass.global_session_options[:integrated].should be_false
      @klass.global_session_options[:raise].should be_true
    end

    it 'should honor :only' do
      @klass.has_global_session(:only=>[:show])
      
      @controller = @klass.new( @env, {}, {}, {:action=>:index} )
      @controller.process({})
      @controller.global_session.should be_nil

      @controller2 = @klass.new( @env, {}, {}, {:action=>:show} )
      @controller2.process({})
      @controller2.global_session.should_not be_nil
    end

    it 'should honor :except' do
      @klass.has_global_session(:except=>[:show])

      @controller = @klass.new( @env, {}, {}, {:action=>:show} )
      @controller.process({})
      @controller.global_session.should be_nil

      @controller2 = @klass.new( @env, {}, {}, {:action=>:index} )
      @controller2.process({})
      @controller2.global_session.should_not be_nil
    end
  end

  context 'with inheritance' do
    it 'should inherit options from the base class'

    it 'should allow derived-class options to override base-class options'

    it 'should handle a child class that overrides :except with :only' do
      @parent = Class.new(StubController) do
        has_global_session(:except=>[:index])
      end

      @child = Class.new(@parent) do
        has_global_session(:only=>[:index, :show])
      end

      @controller2 = @child.new( @env, {}, {}, {:action=>:index} )
      @controller2.process({})
      @controller2.global_session.should_not be_nil
    end

    it 'should handle a child class that overrides :only with :except' do
      @parent = Class.new(StubController) do
        has_global_session(:only=>[:index])
      end

      @child = Class.new(@parent) do
        has_global_session(:except=>[:index, :show])
      end

      @controller2 = @child.new( @env, {}, {}, {:action=>:index} )
      @controller2.process({})
      @controller2.global_session.should be_nil
    end
  end
end