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

module GlobalSession
  # Rails integration for GlobalSession.
  #
  # The configuration file for Rails apps is located in +config/global_session.yml+ and a generator
  # (global_session_config) is available for creating a sensible default.
  #
  # There is also a generator (global_session_authority) for creating authority keypairs.
  #
  # The main integration touchpoint for Rails is the module ActionControllerInstanceMethods,
  # which gets mixed into ActionController::Base. This is where all of the magic happens..
  #
  module Rails
    # Module that is mixed into ActionController-derived classes when the class method
    # +has_global_session+ is called.
    #
    module ActionControllerInstanceMethods
      def self.included(base) # :nodoc:
        #Make sure a superclass hasn't already chained the methods...
        unless base.instance_methods.include?("session_without_global_session")
          base.alias_method_chain :session, :global_session
        end
        unless base.instance_methods.include?("log_processing_without_global_session")
          base.alias_method_chain :log_processing, :global_session
        end

        base.before_filter :global_session_initialize
      end

      def global_session_options
        self.class.global_session_options
      end

      # Global session reader.
      #
      # === Return
      # session(Session):: the global session associated with the current request, nil if none
      def global_session
        @global_session
      end

      # Aliased version of ActionController::Base#session which will return the integrated
      # global-and-local session object (IntegratedSession).
      #
      # === Return
      # session(IntegratedSession):: the integrated session
      def session_with_global_session
        if global_session_options[:integrated] && global_session
          unless @integrated_session &&
                 (@integrated_session.local == session_without_global_session) && 
                 (@integrated_session.global == global_session)
            @integrated_session =
              IntegratedSession.new(session_without_global_session, global_session)
          end
          
          return @integrated_session
        else
          return session_without_global_session
        end
      end

      # Filter to initialize the global session.
      #
      # === Return
      # true:: Always returns true
      def global_session_initialize
        options = global_session_options

        if options[:only] && !options[:only].include?(action_name)
          should_skip = true
        elsif options[:except] && options[:except].include?(action_name)
          should_skip = true
        elsif !options[:enabled]
          should_skip = true
        end

        if should_skip
          request.env['global_session.req.renew'] = false
          request.env['global_session.req.update'] = false
        else
          request.env['global_session.req.renew'] = options[:renew]
          error = request.env['global_session.error']
          raise error if error.present? && options[:raise]
          @global_session = request.env['global_session']
        end

        return true
      end

      # Override for the ActionController method of the same name that logs
      # information about the request. Our version logs the global session ID
      # instead of the local session ID.
      #
      # === Parameters
      # name(Type):: Description
      #
      # === Return
      # name(Type):: Description
      def log_processing_with_global_session
        return unless logger && logger.info?

        gs = request.env['global_session']
        
        if gs && gs.id
          session_data = {}
          gs.each_pair { |key, value| session_data[key] = value }

          session_id = gs.id + " (#{session[:session_id] || request.session_options[:id]})"
        elsif session[:session_id]
          session_id = session[:session_id]
        elsif request.session_options[:id]
          session_id = request.session_options[:id]
        end

        request_id = "\n\nProcessing #{self.class.name}\##{action_name} "
        request_id << "to #{params[:format]} " if params[:format]
        request_id << "(for #{request_origin.split[0]}) [#{request.method.to_s.upcase}]"
        request_id << "\n  Session ID: #{session_id}" if session_id
        request_id << "\n  Session Data: #{session_data.inspect}" if session_data

        logger.info(request_id)

        parameters = respond_to?(:filter_parameters) ? filter_parameters(params) : params.dup
        parameters = parameters.except!(:controller, :action, :format, :_method)

        logger.info "  Parameters: #{parameters.inspect}" unless parameters.empty?
      end
    end
  end
end
