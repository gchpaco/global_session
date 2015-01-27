require 'spec_helper'

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

  [GlobalSession::Session::V1,GlobalSession::Session::V2,GlobalSession::Session::V3].each do |k|
    context "given a valid serialized #{k}" do
      before :each do
        @cookie = k.new(@directory).to_s
      end

      context '.new' do
        it 'creates a compatible session object' do
          @session = GlobalSession::Session.new(@directory, @cookie)
          @session.should be_a(k)
        end
      end

      context '.decode_cookie' do
        it 'returns useful debug info' do
          h = k.decode_cookie(@cookie)
          h.should respond_to(:each)
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
