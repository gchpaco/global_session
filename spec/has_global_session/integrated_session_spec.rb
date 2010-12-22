require File.expand_path(File.join(File.dirname(__FILE__), '..' , 'spec_helper'))

include GlobalSession

describe IntegratedSession do
  include SpecHelper

  before(:each) do
    @global  = flexmock('Global Session')
    @local   = flexmock('Local Session')
    @session = IntegratedSession.new(@local, @global)
  end
  
  context :[] do
    it 'should get elements of the global session' do
      @global.should_receive(:supports_key?).with('global key').and_return(true)
      @global.should_receive(:[]).with('global key').and_return('global value')

      @session['global key'].should == 'global value'
    end

    it 'should get elements of the local session' do
      @global.should_receive(:supports_key?).with('local key').and_return(false)
      @local.should_receive(:[]).with('local key').and_return('local value')

      @session['local key'].should == 'local value'
    end
  end

  context :[]= do
    it 'should set elements of the global session' do
      @global.should_receive(:supports_key?).with('global key').and_return(true)
      @global.should_receive(:[]=).with('global key', 'global value').once

      @session['global key'] = 'global value'
    end

    it 'should set elements of the local session' do
      @global.should_receive(:supports_key?).with('local key').and_return(false)
      @global.should_receive(:[]=).never
      @local.should_receive(:[]=).with('local key', 'local value').once

      @session['local key'] = 'local value'
    end
  end

  context :has_key? do
    it 'should return true if either local or global has the key' do
      @global.should_receive(:has_key?).with('global key').and_return(true)
      @global.should_receive(:has_key?).with('local key').and_return(false)
      @local.should_receive(:has_key?).with('local key').and_return(true)

      @session.has_key?('global key').should be_true
      @session.has_key?('local key').should be_true
    end
  end

  context :keys do
    it 'should return the union of the global and local keys' do
      @global.should_receive(:keys).and_return(['global key'])
      @local.should_receive(:keys).and_return(['local key'])

      @session.keys.sort.should == ['global key', 'local key'].sort
    end
  end

  context :values do
    it 'should return the union of the global and local values' do
      @global.should_receive(:values).and_return(['global value'])
      @local.should_receive(:values).and_return(['local value'])

      @session.values.sort.should == ['global value', 'local value'].sort
    end
  end

  context :each_pair do
    it 'iterate over all key/value pairs of global and local sessions' do
      @global.should_receive(:each_pair).and_yield('global key', 'global value')
      @local.should_receive(:each_pair).and_yield('local key', 'local value')

      result = {}
      @session.each_pair { |k,v| result[k] = v }

      result.should == {'global key'=>'global value', 'local key'=>'local value'}
    end
  end

  context :method_missing do
    it 'should dispatch to the global session first' do
      @global.should_receive(:respond_to?).with(:global_method).and_return(true)
      @global.should_receive(:global_method).and_return('global return value')
      @local.should_receive(:respond_to?).with(:global_method).never

      @session.global_method.should == 'global return value'
    end

    it 'should dispatch to the local session as a fallback' do
      @global.should_receive(:respond_to?).with(:local_method).and_return(false)
      @local.should_receive(:respond_to?).with(:local_method).and_return(true)
      @local.should_receive(:local_method).and_return('local return value')

      @session.local_method.should == 'local return value'
    end

    it 'should call super if neither global nor local supports the method' do
      @global.should_receive(:respond_to?).with(:random_method).and_return(false)
      @local.should_receive(:respond_to?).with(:random_method).and_return(false)

      lambda {
        @session.random_method
      }.should raise_error(NoMethodError)
    end
  end

  context :respond_to? do
    it 'should return true if the method is supported by either global or local' do
      @global.should_receive(:respond_to?).with(:global_method).and_return(true)
      @global.should_receive(:respond_to?).with(:local_method).and_return(false)
      @local.should_receive(:respond_to?).with(:local_method).and_return(true)
      @local.should_receive(:respond_to?).with(:global_method).and_return(false)

      @session.respond_to?(:global_method).should == true
      @session.respond_to?(:local_method).should == true
    end
  end
end