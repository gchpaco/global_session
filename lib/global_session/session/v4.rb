require 'securerandom'

module GlobalSession::Session
  # Version 4 is based on JSON Web Token; in fact, if there is no insecure
  # state, then a V4 session _is_ a JWT. Otherwise, it's a JWT with a
  # nonstandard fourth component containing the insecure state.
  class V4 < Abstract
    EXPIRED_AT = 'exp'.freeze
    ID         = 'id'.freeze
    ISSUED_AT  = 'iat'.freeze
    ISSUER     = 'iss'.freeze
    NOT_BEFORE = 'nbf'.freeze

    # Pattern that matches strings that are probably a V4 session cookie.
    HEADER = /^eyJ0eXAiOiJKV1QiL/

    def self.decode_cookie(cookie)
      header, payload, sig, insec = cookie.split('.')
      header, payload, insec = [header, payload, insec].
        map { |c| c && RightSupport::Data::Base64URL.decode(c) }.
        map { |j| j && GlobalSession::Encoding::JSON.load(j) }
      sig = sig && RightSupport::Data::Base64URL.decode(sig)
      insec ||= {}

      unless Hash === header && header['typ'] == 'JWT'
        raise GlobalSession::MalformedCookie, "JWT header not present"
      end
      unless Hash === payload
        raise GlobalSession::MalformedCookie, "JWT payload not present"
      end

      [header, payload, sig, insec]
    rescue JSON::ParserError => e
      raise GlobalSession::MalformedCookie, e.message
    end

    # Serialize the session. If any secure attributes have changed since the
    # session was instantiated, compute a fresh RSA signature.
    #
    # @return [String]
    def to_s
      if @cookie && !dirty?
        # nothing has changed; just return cached cookie
        return @cookie
      end

      unless @insecure.nil? || @insecure.empty?
        insec = GlobalSession::Encoding::JSON.dump(@insecure)
        insec = RightSupport::Data::Base64URL.encode(insec)
      end

      if @signature && !(@dirty_timestamps || @dirty_secure)
        # secure state hasn't changed; reuse JWT piece of cookie
        jwt = @cookie.split('.')[0..2].join('.')
      else
        # secure state has changed; recompute signature & make new JWT
        authority_check

        payload = @signed.dup
        payload[ID] = id
        payload[EXPIRED_AT] = @expired_at.to_i
        payload[ISSUED_AT] = @created_at.to_i
        payload[ISSUER] = @directory.local_authority_name

        sh = RightSupport::Crypto::SignedHash.new(payload, @directory.private_key, envelope: :jwt)
        jwt = sh.to_jwt(@expired_at)
      end

      if insec && !insec.empty?
        return "#{jwt}.#{insec}"
      else
        return jwt
      end
    end

    private

    def load_from_cookie(cookie)
      # Get the basic facts
      header, payload, sig, insec = self.class.decode_cookie(cookie)
      id         = payload[ID]
      created_at = payload[ISSUED_AT]
      issuer     = payload[ISSUER]
      expired_at = payload[EXPIRED_AT]
      not_before = payload[NOT_BEFORE]
      raise GlobalSession::InvalidSignature, "JWT iat claim missing/wrong" unless Integer === created_at
      raise GlobalSession::InvalidSignature, "JWT iat claim missing/wrong" unless Integer === expired_at
      created_at = Time.at(created_at)
      expired_at = Time.at(expired_at)
      if Numeric === not_before
        not_before = Time.at(not_before)
        raise GlobalSession::PrematureSession, "Session not valid before #{not_before}" unless Time.now >= not_before
      end

      #Check trust in signing authority
      if @directory.trusted_authority?(issuer)
        signed_hash =
          RightSupport::Crypto::SignedHash.new(payload,
            @directory.authorities[issuer],
            envelope: :jwt
          )

        begin
          signed_hash.verify!(sig, expired_at)
        rescue RightSupport::Crypto::ExpiredSignature
          raise GlobalSession::ExpiredSession, "Session expired at #{expired_at}"
        rescue RightSupport::Crypto::InvalidSignature => e
          raise GlobalSession::InvalidSignature, "Global session signature verification failed: " + e.message
        end

      else
        raise GlobalSession::InvalidSignature, "Global sessions signed by #{authority.inspect} are not trusted"
      end

      #Check other validity (delegate to directory)
      unless @directory.valid_session?(id, expired_at)
        raise GlobalSession::InvalidSession, "Global session has been invalidated"
      end

      #If all validation stuff passed, assign our instance variables.
      @id = id
      @authority = issuer
      @created_at = created_at
      @expired_at = expired_at
      @signed = payload
      @insecure = insec
      @signature = sig
      @cookie = cookie
    end

    def create_from_scratch
      @signed = {}
      @insecure = {}
      @created_at = Time.now.utc
      @authority = @directory.local_authority_name
      @id = generate_id
      renew!
    end
  end
end
