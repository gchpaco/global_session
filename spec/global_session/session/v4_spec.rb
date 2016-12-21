require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::V4 do
  subject { GlobalSession::Session::V4 }

  include SpecHelper

  context 'given an EC key' do
    let(:key_generation_parameter) { 'prime256v1' }
    let(:signature_method) { :dsa_sign_asn1 }
    let(:approximate_token_size) { 210 }
    it_should_behave_like 'all subclasses of Session::Abstract'

    let(:algorithm_identifier) { 'ES256' }
    it_should_behave_like 'JWT compatible subclasses of Session::Abstract'
  end

  context 'given an RSA key' do
    let(:key_generation_parameter) { 1024 }
    let(:signature_method) { :dsa_sign_asn1 }
    let(:approximate_token_size) { 280 }
    it_should_behave_like 'all subclasses of Session::Abstract'

    let(:algorithm_identifier) { 'RS256' }
    it_should_behave_like 'JWT compatible subclasses of Session::Abstract'
  end
end
