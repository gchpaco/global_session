require 'spec_helper'

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
    mock_config('test/trust', ['authority1'])
    mock_config('test/authority', 'authority1')
    mock_config('common/attributes/signed', ['user'])
    mock_config('common/attributes/insecure', ['favorite_color'])
    mock_config('test/timeout', '60')
    @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
  end

  context 'given a valid V2 cookie' do
    before :each do
      @cookie = GlobalSession::Session::V2.new(@directory).to_s
    end

    context :new do
      it 'creates a V2 session' do
        @session = GlobalSession::Session.new(@directory, @cookie)
        @session.should be_a(GlobalSession::Session::V2)
      end
    end

    context :decode_cookie do
      it 'returns a hash with some useful stuff'
    end
  end

  context 'given a valid V1 cookie' do
    before :each do
      @session = GlobalSession::Session::V1.new(@directory)
      @cookie = @session.to_s
    end

    context :new do
      it 'creates a V1 session' do
        @session = GlobalSession::Session.new(@directory, @cookie)
        @session.should be_a(GlobalSession::Session::V1)
      end
    end

    context :decode_cookie do
      it 'returns a hash with some useful stuff'
    end
  end

  context 'given garbage' do
    it 'raises ArgumentError'
  end
end
