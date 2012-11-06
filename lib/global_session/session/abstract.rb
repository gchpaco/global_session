module GlobalSession::Session
  # An abstract base class for all versions of the global session.
  # Defines common attributes and methods.
  class Abstract
    attr_reader :id, :authority, :created_at, :expired_at, :directory
    attr_reader :signed, :insecure

    # Create a new global session object.
    #
    # === Parameters
    # directory(Directory):: directory implementation that the session should use for various operations
    #
    # ===Raise
    # InvalidSession:: if the session contained in the cookie has been invalidated
    # ExpiredSession:: if the session contained in the cookie has expired
    # MalformedCookie:: if the cookie was corrupt or malformed
    # SecurityError:: if signature is invalid or cookie is not signed by a trusted authority
    def initialize(directory)
      @directory = directory
      @signed = {}
      @insecure = {}
    end

    # @return a representation of the object suitable for printing to the console
    def inspect
      "<#{self.class.name}(#{self.id})>"
    end

    # @return a Hash representation of the session with three subkeys: :metadata, :signed and :insecure
    # @raise nothing -- does not raise; returns empty hash if there is a failure
    def to_hash
      hash = {}

      md = {}
      signed = {}
      insecure = {}

      hash[:metadata] = md
      hash[:signed] = signed
      hash[:insecure] = insecure

      md[:id] = @id
      md[:authority] = @authority
      md[:created_at] = @created_at
      md[:expired_at] = @expired_at
      @signed.each_pair { |k, v| signed[k] = v }
      @insecure.each_pair { |k, v| insecure[k] = v }

      hash
    rescue Exception => e
      {}
    end

    # Invalidate this session by reporting its UUID to the Directory.
    #
    # === Return
    # unknown(Object):: Returns whatever the Directory returns
    def invalidate!
      @directory.report_invalid_session(@id, @expired_at)
    end

    # Renews this global session, changing its expiry timestamp into the future.
    # Causes a new signature will be computed when the session is next serialized.
    #
    # === Return
    # true:: Always returns true
    def renew!(expired_at=nil)
      authority_check
      minutes = Integer(@configuration['timeout'])
      expired_at ||= Time.at(Time.now.utc + 60 * minutes)
      @expired_at = expired_at
      @created_at = Time.now.utc
    end

    private

    def authority_check # :nodoc:
      unless @directory.local_authority_name
        raise GlobalSession::NoAuthority, 'Cannot change secure session attributes; we are not an authority'
      end
    end
  end
end