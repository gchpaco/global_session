require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::V4 do
  subject { GlobalSession::Session::V4 }

  include SpecHelper

  let(:key_generation_parameter) { 'prime256v1' }
  let(:signature_method) { :dsa_sign_asn1 }
  let(:approximate_token_size) { 196 }
  it_should_behave_like 'all subclasses of Session::Abstract'
end
