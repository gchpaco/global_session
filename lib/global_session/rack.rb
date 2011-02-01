require File.expand_path(File.join(File.dirname(__FILE__), "..", "global_session"))

# Make sure the namespace exists, to satisfy Rails auto-loading
module GlobalSession
  module Rack
    # Global session middleware.  Note: this class relies on
    # Rack::Cookies being used higher up in the chain.
    class Middleware
      # Make a new global session.
      #
      # The optional block here controls an alternate ticket retrieval
      # method.  If no ticket is stored in the cookie jar, this
      # function is called.  If it returns a non-nil value, that value
      # is the ticket.
      #
      # === Parameters
      # app(Rack client): application to run
      # configuration(String or Configuration): global_session configuration.
      #                                         If a string, is interpreted as a
      #                                         filename to load the config from.
      # directory(String or Directory):         Directory object that provides
      #                                         trust services to the global
      #                                         session implementation. If a
      #                                         string, is interpreted as a
      #                                         filesystem directory containing
      #                                         the public and private keys of
      #                                         authorities, from which default
      #                                         trust services will be initialized.
      #
      # block: optional alternate ticket retrieval function
      def initialize(app, configuration, directory, &block)
        @app = app

        if configuration.instance_of?(String)
          @configuration = Configuration.new(configuration, ENV['RACK_ENV'] || 'development')
        else
          @configuration = configuration
        end

        if directory.instance_of?(String)
          @directory = Directory.new(@configuration, directory)
        else
          @directory = directory
        end

        @cookie_retrieval = block
        @cookie_name = @configuration['cookie']['name']
      end

      # Read a cookie from the Rack environment.
      #
      # === Parameters
      # env(Hash): Rack environment.
      def read_cookie(env)
        if env['rack.cookies'].has_key?(@cookie_name)
          env['global_session'] = Session.new(@directory,
                                              env['rack.cookies'][@cookie_name])
        elsif @cookie_retrieval && cookie = @cookie_retrieval.call(env)
          env['global_session'] = Session.new(@directory, cookie)
        else
          env['global_session'] = Session.new(@directory)
        end

        true
      end

      # Renew the session ticket.
      #
      # === Parameters
      # env(Hash): Rack environment
      def renew_cookie(env)
        return unless env['global_session'].directory.local_authority_name
        return if env['global_session.req.renew'] == false

        if (renew = @configuration['renew']) && env['global_session'] &&
            env['global_session'].expired_at < Time.at(Time.now.utc + 60 * renew.to_i)
          env['global_session'].renew!
        end
      end

      # Update the cookie jar with the revised ticket.
      #
      # === Parameters
      # env(Hash): Rack environment
      def update_cookie(env)
        return unless env['global_session'].directory.local_authority_name
        return if env['global_session.req.update'] == false

        begin
          domain = @configuration['cookie']['domain'] || env['SERVER_NAME']
          if env['global_session'] && env['global_session'].valid?
            value = env['global_session'].to_s
            expires = @configuration['ephemeral'] ? nil : env['global_session'].expired_at
            unless env['rack.cookies'].has_key?(@cookie_name) &&
                env['rack.cookies'][@cookie_name] == value
              env['rack.cookies'][@cookie_name] = {:value => value, :domain => domain, :expires => expires}
            end
          else
            # write an empty cookie
            env['rack.cookies'][@cookie_name] = {:value => nil, :domain => domain, :expires => Time.at(0)}
          end
        rescue Exception => e
          wipe_cookie(env)
          raise e
        end
      end

      # Delete the global session cookie from the cookie jar.
      #
      # === Parameters
      # env(Hash): Rack environment
      def wipe_cookie(env)
        return unless env['global_session'].directory.local_authority_name
        return if env['global_session.req.update'] == false

        domain = @configuration['cookie']['domain'] || env['SERVER_NAME']
        env['rack.cookies'][@cookie_name] = {:value => nil, :domain => domain, :expires => Time.at(0)}
      end

      # Handle exceptions that occur during app invocation. This will either save the error
      # in the Rack environment or raise it, depending on the type of error. The error may
      # also be logged.
      #
      # === Parameters
      # activity(String): name of activity in which error happened
      # env(Hash): Rack environment
      # e(Exception): error that happened
      def handle_error(activity, env, e)
        env['rack.logger'].error("#{e.class} while #{activity}: #{e} #{e.backtrace}") if env['rack.logger']

        if e.is_a?(ClientError) || e.is_a?(SecurityError)
          env['global_session.error'] = e
          wipe_cookie(env)
        elsif e.is_a? ConfigurationError
          env['global_session.error'] = e
        else
          raise e
        end
      end

      # Rack request chain. Sets up the global session ticket from
      # the environment and passes it up the chain.
      def call(env)
        env['rack.cookies'] = {} unless env['rack.cookies']

        begin
          read_cookie(env)
        rescue Exception => e
          env['global_session'] = Session.new(@directory)
          handle_error('reading session cookie', env, e)
        end

        tuple = nil

        begin
          tuple = @app.call(env)
        rescue Exception => e
          handle_error('processing request', env, e)
          return tuple
        else
          renew_cookie(env)
          update_cookie(env)
          return tuple
        end
      end
    end
  end
end

module Rack
  GlobalSession = ::GlobalSession::Rack::Middleware unless defined?(::Rack::GlobalSession)
end
