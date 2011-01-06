basedir = File.dirname(__FILE__)

require 'rack/contrib/cookies'
require 'action_pack'
require 'action_controller'

#Require the files necessary for Rails integration
require 'global_session/rack'
require 'global_session/rails/action_controller_class_methods'
require 'global_session/rails/action_controller_instance_methods'

module GlobalSession
  module Rails
    def self.activate(config)
      # Enable ActionController integration.
      class <<ActionController::Base
        include GlobalSession::Rails::ActionControllerClassMethods
      end

      ActionController::Base.instance_eval do
        include GlobalSession::Rails::ActionControllerInstanceMethods
      end

      authorities = File.join(::Rails.root, 'config', 'authorities')
      hgs_config  = ActionController::Base.global_session_config
      hgs_dir     = GlobalSession::Directory.new(hgs_config, authorities)

      # Add our middleware to the stack.
      config.middleware.use ::Rack::Cookies
      config.middleware.use ::Rack::GlobalSession, hgs_config, hgs_dir

      return true
    end
  end
end
