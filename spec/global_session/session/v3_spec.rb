require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::V3 do
  it_should_behave_like 'all subclasses of Session::Abstract'

  before(:each) do
    mock_config('test/trust', ['authority1'])
    mock_config('test/authority', 'authority1')
    mock_config('common/attributes/signed', ['user'])
    mock_config('common/attributes/insecure', ['favorite_color'])
    @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
    @original_session = described_class.new(@directory)
    @cookie           = @original_session.to_s
  end

  context 'cookie size' do
    it 'has size ~260 bytes' do
      size  = 0
      count = 0
      100.times do
        session = described_class.new(@directory)
        size += session.to_s.size
        count += 1
      end

      (Float(size) / Float(count)).should be_close(285, 5)
    end
  end

  context '#to_s' do
    context 'when the session contains unserializable keys' do
      before(:each) do
        @original_session['user'] = {1=>[2,3]}
      end

      it 'raises UnserializableType' do
        expect {
          @original_session.to_s
        }.to raise_error(GlobalSession::UnserializableType)
      end
    end
  end
end