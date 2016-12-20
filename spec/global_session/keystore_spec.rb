require File.expand_path(File.join(File.dirname(__FILE__), '..' , 'spec_helper'))

describe GlobalSession::Keystore do
  include SpecHelper

  context '.create_keypair' do
    [:RSA, :DSA, :EC].each do |alg|
      it "makes #{alg} keys" do
        key = GlobalSession::Keystore.create_keypair(alg)
      end
    end
  end

  it 'reads various PEM formats' do
    fixtures_dir = File.expand_path('../../fixtures', __FILE__)
    config = {'keystore' => {'public' => fixtures_dir}}

    keystore = GlobalSession::Keystore.new(config)
  end
end
