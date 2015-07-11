require 'spec_helper'

# Unit tests of the Session module, plus common behavior for all classes/
# subclasses defined in the module
describe GlobalSession::Session do
  include SpecHelper

  before(:all) do
    @key_factory = KeyFactory.new
    @key_factory.create('authority1', true)
    @key_factory.create('authority2', false)
  end

  after(:all) do
    @key_factory.destroy
  end

  before(:each) do
    mock_config('test/trust', ['authority1'])
    mock_config('test/authority', 'authority1')
    mock_config('common/attributes/signed', ['user'])
    mock_config('common/attributes/insecure', ['favorite_color'])
    mock_config('test/timeout', '60')
    @directory        = GlobalSession::Directory.new(mock_config, @key_factory.dir)
  end

  (1..3).each do |version|
    context "V#{version}" do
      let(:klass) { GlobalSession::Session.const_get("V#{version}".to_sym) }
      let(:cookie)  { klass.new(@directory).to_s }

      context '.new' do
        it 'creates a compatible session object' do
          session = GlobalSession::Session.new(@directory, cookie)
          session.should be_a(klass)
        end
      end

      context '.decode_cookie' do
        it 'returns useful debug info' do
          h = klass.decode_cookie(cookie)
          h.should respond_to(:each)
        end
      end

      context '#new_record?' do
        let(:session) { GlobalSession::Session.new(@directory, cookie) }

        it 'returns false when loaded from a cookie' do
          session.new_record?.should be_false
        end

        it 'returns true when created from scratch' do
          klass.new(@directory).new_record?.should be_true
        end
      end

      context '#dirty?' do
        let(:session) { GlobalSession::Session.new(@directory, cookie) }

        it 'returns false when nothing changes' do
          session.dirty?.should be_false
        end

        it 'detects timestamp changes' do
          session.renew!
          session.dirty?.should be_true
        end

        it 'detects data changes' do
          session['user'] = 'your momma'
          session.dirty?.should be_true
        end
      end

      context '#to_s' do
        let(:session) { GlobalSession::Session.new(@directory, cookie) }
        let(:reloaded_session) { GlobalSession::Session.new(@directory, session.to_s) }

        it 'recomputes signature when secure attributes change' do
          session['user'] = 123456
          reloaded_session['user'].should == 123456
        end

        it 'recomputes signature when expired_at changes' do
          session.renew!
          reloaded_session.expired_at.should be_close(session.expired_at, 1)
        end
      end
    end
  end

  context 'given garbage' do
    context '.new' do
      it 'raises MalformedCookie' do
        expect {
          GlobalSession::Session.new(@directory, 'hi mom')
        }.to raise_error(GlobalSession::MalformedCookie)
      end
    end
  end
end
