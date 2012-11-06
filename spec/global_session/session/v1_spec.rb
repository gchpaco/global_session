require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::V1 do
  it_should_behave_like 'all subclasses of Session::Abstract'

  context :initialize do
    before(:each) do
      mock_config('test/trust', ['authority1'])
      mock_config('test/authority', 'authority1')
      @directory        = GlobalSession::Directory.new(mock_config, @keystore.dir)
      @original_session = described_class.new(@directory)
      @cookie           = @original_session.to_s
    end

    context 'when a trusted signature is passed in' do
      it 'should not recompute the signature' do
        flexmock(@directory.authorities['authority1']).should_receive(:public_decrypt).never
        valid_digest = @original_session.signature_digest
        described_class.new(@directory, @cookie, valid_digest).should be_a(GlobalSession::Session::Abstract)
      end
    end
  end
end
