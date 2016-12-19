require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::V3 do
  subject { GlobalSession::Session::V3 }

  include SpecHelper

  let(:key_generation_parameter) { 1024 }
  let(:signature_method) { :sign }
  let(:approximate_token_size) { 260 }
  it_should_behave_like 'all subclasses of Session::Abstract'
end
