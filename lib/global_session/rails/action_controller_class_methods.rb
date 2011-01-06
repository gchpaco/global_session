module GlobalSession
  module Rails
    # Module that is mixed into ActionController's eigenclass; provides access to shared
    # app-wide data such as the configuration object, and implements the DSL used to
    # configure controllers' use of the global session.
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
        odefault = {:integrated=>false, :raise=>true}
        obase = self.superclass.global_session_options if self.superclass.respond_to?(:global_session_options)
        obase ||= {}
        options = odefault.merge(obase).merge(options)

        #ensure derived-class options don't conflict with mutually exclusive base-class options
        options.delete(:only) if obase.has_key?(:only) && options.has_key?(:except)
        options.delete(:except) if obase.has_key?(:except) && options.has_key?(:only)

        #mark the global session as enabled (a hidden option) and store our
        #calculated, merged options
        options[:enabled] = true
        self.global_session_options = options

        before_filter :global_session_initialize
      end

      def no_global_session
        @global_session_options[:enabled] = false if @global_session_options
        skip_before_filter :global_session_initialize
      end

      def global_session_options
        obase = self.superclass.global_session_options if self.superclass.respond_to?(:global_session_options) 
        obase ||= {}
        @global_session_options || obase
      end

      def global_session_options=(options)
        @global_session_options = options
      end      
    end
  end
end