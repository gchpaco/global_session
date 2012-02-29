# Copyright (c) 2012 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

basedir = File.dirname(__FILE__)

require 'rack/contrib/cookies'
require 'action_pack'
require 'action_controller'

#Require the files necessary for Rails integration
require 'global_session/rack'
require 'global_session/rails/action_controller_class_methods'
require 'global_session/rails/action_controller_instance_methods'

# Enable ActionController integration.
class <<ActionController::Base
  include GlobalSession::Rails::ActionControllerClassMethods
end

ActionController::Base.instance_eval do
  include GlobalSession::Rails::ActionControllerInstanceMethods
end

module GlobalSession
  module Rails
    def self.activate(config)
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
