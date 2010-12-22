basedir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$: << File.join(basedir, 'lib')

require 'tempfile'

require 'rubygems'
require 'flexmock'

require 'global_session'

# Setup Rails (for Rails integration specs)
gem 'actionpack', '>= 2.1.2'
require 'action_controller'
require 'global_session/rails'

# Enable ActionController integration with Rails. Since we're not actually activating
# the Rails plugin, we need to do this ourselves.
class <<ActionController::Base
  include GlobalSession::Rails::ActionControllerClassMethods
end

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

class KeyFactory
  def initialize()
    @keystore = File.join( Dir.tmpdir, "#{Process.pid}_#{rand(2**32)}" )
    FileUtils.mkdir_p(@keystore)
  end

  def dir
    @keystore
  end

  def create(name, write_private)
    new_key     = OpenSSL::PKey::RSA.generate(1024)
    new_public  = new_key.public_key.to_pem
    new_private = new_key.to_pem
    File.open(File.join(@keystore, "#{name}.pub"), 'w') { |f| f.puts new_public }
    File.open(File.join(@keystore, "#{name}.key"), 'w') { |f| f.puts new_key } if write_private
  end

  def reset()
    FileUtils.rm_rf(File.join(@keystore, '*'))
  end

  def destroy()
    FileUtils.rm_rf(@keystore)
  end
end

module SpecHelper
  # Getter for the GlobalSession::Configuration object
  # used by tests. It doubles as a mechanism for stuffing
  # config elements into said object.
  def mock_config(path=nil, value=nil)
    @mock_config ||= GlobalSession::Configuration.allocate
    @mock_config.instance_variable_set(:@environment, 'test')
    hash = @mock_config.instance_variable_get(:@config) || {}
    @mock_config.instance_variable_set(:@config, hash)

    if(path || value)
      path = path.split('/')
      first_keys = path[0...-1]
      last_key   = path.last
      first_keys.each do |key|
        hash[key] ||= {}
        hash = hash[key]
      end
      hash[last_key] = value
    end

    return @mock_config
  end

  def reset_mock_config
    @mock_config = nil
  end
end