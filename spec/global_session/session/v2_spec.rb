require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::V2 do
  it_should_behave_like 'all subclasses of Session::Abstract'

  context 'cookie size' do
    before(:each) do
      mock_config('test/trust', ['authority1'])
      mock_config('test/authority', 'authority1')
      @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
      @original_session = described_class.new(@directory)
      @cookie           = @original_session.to_s
    end

    it 'has size ~260 bytes' do
      size  = 0
      count = 0
      100.times do
        session = described_class.new(@directory)
        size += session.to_s.size
        count += 1
      end

      (Float(size) / Float(count)).should be_close(260, 5)
    end
  end
end