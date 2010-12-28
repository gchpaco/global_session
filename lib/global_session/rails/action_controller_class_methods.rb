module GlobalSession
  module Rails
    # Module that is mixed into ActionController's eigenclass; provides access to shared
    # app-wide data such as the configuration object.
    module ActionControllerClassMethods
      def global_session_config
        unless @global_session_config
          config_file = File.join(::Rails.root, 'config', 'global_session.yml')
          @global_session_config = GlobalSession::Configuration.new(config_file, RAILS_ENV)
        end

        return @global_session_config
      end

      def global_session_config=(config)
        @global_session_config = config
      end

      def has_global_session(options={})
        odefault = {:integrated=>false}
        obase = self.superclass.global_session_options if self.superclass.respond_to?(:global_session_options)
        options = odefault.merge(obase).merge(options)
        
        self.global_session_options = HashWithIndifferentAccess.new(options)
        options = self.global_session_options

        include GlobalSession::Rails::ActionControllerInstanceMethods

        fopt = {}
        inverse_fopt = {}
        fopt[:only] = options[:only] if options[:only]
        fopt[:except] = options[:except] if options[:except]
        inverse_fopt[:only] = options[:except] if options[:except]
        inverse_fopt[:except] = options[:only] if options[:only]

        if fopt[:only] || fopt[:except]
          before_filter :global_session_skip_renew, inverse_fopt
          before_filter :global_session_skip_update, inverse_fopt
        end

        before_filter :global_session_initialize, fopt
      end

      def no_global_session
        skip_before_filter :global_session_initialize
        before_filter :global_session_skip_renew
        before_filter :global_session_skip_update
      end

      def global_session_options
        @global_session_options || {}
      end

      def global_session_options=(options)
        @global_session_options = options
      end      
    end
  end
end