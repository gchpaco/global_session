require 'spec_helper'
require File.expand_path('../shared_examples', __FILE__)

describe GlobalSession::Session::V1 do
  it_should_behave_like 'all subclasses of Session::Abstract'
end