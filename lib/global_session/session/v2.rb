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

# Standard library dependencies
require 'set'

# Cryptographical Hash
require 'right_support/crypto'

module GlobalSession::Session
  # Global session V2 uses msgpack serialization and no compression. Its msgpack structure is an
  # Array with the following format:
  #  [<uuid_string>,
  #   <signing_authority_string>,
  #   <creation_timestamp_integer>,
  #   <expiration_timestamp_integer>,
  #   {<signed_data_hash>},
  #   {<unsigned_data_hash>},
  #   <binary_signature_string>]
  #
  # The design goal of V2 is to minimize the size of the base64-encoded session state in order
  # to make GlobalSession more amenable to use as a browser cookie.
  #
  # Limitations of V2 include the following:
  # * Some Ruby implementations (e.g. JRuby) lack a msgpack library
  # * The sign and verify algorithms, while safe, do not comply fully with PKCS7; they rely on the
  #   OpenSSL low-level crypto API instead of using the higher-level EVP (envelope) API.
  class V2 < Abstract
    # Utility method to decode a cookie; good for console debugging. This performs no
    # validation or security check of any sort.
    #
    # === Parameters
    # cookie(String):: well-formed global session cookie
    def self.decode_cookie(cookie)
      msgpack = GlobalSession::Encoding::Base64Cookie.load(cookie)
      return GlobalSession::Encoding::Msgpack.load(msgpack)
    end

    # Serialize the session to a form suitable for use with HTTP cookies. If any
    # secure attributes have changed since the session was instantiated, compute
    # a fresh RSA signature.
    #
    # === Return
    # cookie(String):: Base64Cookie-encoded, Msgpack-serialized global session
    def to_s
      if @cookie && !dirty?
        #use cached cookie if nothing has changed
        return @cookie
      end

      hash = {'id' => @id,
              'tc' => @created_at.to_i, 'te' => @expired_at.to_i,
              'ds' => @signed}

      if @signature && !dirty?
        #use cached signature unless we've changed secure state
        authority = @authority
      else
        authority_check
        authority = @directory.local_authority_name
        hash['a'] = authority
        signed_hash = RightSupport::Crypto::SignedHash.new(
            hash.reject { |k,v| ['dx', 's'].include?(k) },
            :encoding=>GlobalSession::Encoding::Msgpack,
            :private_key=>@directory.private_key)
        @signature = signed_hash.sign(@expired_at)
      end

      hash['dx'] = @insecure
      hash['s'] = @signature
      hash['a'] = authority

      array = attribute_hash_to_array(hash)
      msgpack = GlobalSession::Encoding::Msgpack.dump(array)
      return GlobalSession::Encoding::Base64Cookie.dump(msgpack)
    end

    # Determine whether any state has changed since the session was loaded.
    #
    # @return [Boolean] true if something has changed
    def dirty?
      !!(super || @dirty_secure || @dirty_insecure)
    end

    # Return the keys that are currently present in the global session.
    #
    # === Return
    # keys(Array):: List of keys contained in the global session
    def keys
      @signed.keys + @insecure.keys
    end

    # Return the values that are currently present in the global session.
    #
    # === Return
    # values(Array):: List of values contained in the global session
    def values
      @signed.values + @insecure.values
    end

    # Iterate over each key/value pair
    #
    # === Block
    # An iterator which will be called with each key/value pair
    #
    # === Return
    # Returns the value of the last expression evaluated by the block
    def each_pair(&block) # :yields: |key, value|
      @signed.each_pair(&block)
      @insecure.each_pair(&block)
    end

    # Lookup a value by its key.
    #
    # === Parameters
    # key(String):: the key
    #
    # === Return
    # value(Object):: The value associated with +key+, or nil if +key+ is not present
    def [](key)
      key = key.to_s #take care of symbol-style keys
      @signed[key] || @insecure[key]
    end

    # Set a value in the global session hash. If the supplied key is denoted as
    # secure by the global session schema, causes a new signature to be computed
    # when the session is next serialized.
    #
    # === Parameters
    # key(String):: The key to set
    # value(Object):: The value to set
    #
    # === Return
    # value(Object):: Always returns the value that was set
    #
    # ===Raise
    # InvalidSession:: if the session has been invalidated (and therefore can't be written to)
    # ArgumentError:: if the configuration doesn't define the specified key as part of the global session
    # NoAuthority:: if the specified key is secure and the local node is not an authority
    # UnserializableType:: if the specified value can't be serialized as msgpack
    def []=(key, value)
      key = key.to_s #take care of symbol-style keys
      raise GlobalSession::InvalidSession unless valid?

      if @schema_signed.include?(key)
        authority_check
        @signed[key] = value
        @dirty_secure = true
      elsif @schema_insecure.include?(key)
        @insecure[key] = value
        @dirty_insecure = true
      else
        raise ArgumentError, "Attribute '#{key}' is not specified in global session configuration"
      end

      return value
    end

    # Return the SHA1 hash of the most recently-computed RSA signature of this session.
    # This isn't really intended for the end user; it exists so the Web framework integration
    # code can optimize request speed by caching the most recently verified signature in the
    # local session and avoid re-verifying it on every request.
    #
    # === Return
    # digest(String):: SHA1 hex-digest of most-recently-computed signature
    def signature_digest
      @signature ? digest(@signature) : nil
    end

    private

    # Transform a V1-style attribute hash to an Array with fixed placement for
    # each element. The V2 scheme stores an array in the cookie instead of a hash
    # to save space.
    #
    # === Parameters
    # hash(Hash):: the attribute hash
    #
    # === Return
    # attributes(Array)::
    #
    def attribute_hash_to_array(hash)
      [
        hash['id'],
        hash['a'],
        hash['tc'],
        hash['te'],
        hash['ds'],
        hash['dx'],
        hash['s']
      ]
    end

    # Transform a V2-style attribute array to a Hash with the traditional attribute
    # names. This is good for passing to SignedHash, or initializing a V1 session for
    # downrev compatibility.
    #
    # === Parameters
    # hash(Hash):: the attribute hash
    #
    # === Return
    # attributes(Array):: fixed-position attributes array
    #
    def attribute_array_to_hash(array)
      {
        'id' => array[0],
        'a'  => array[1],
        'tc' => array[2],
        'te' => array[3],
        'ds' => array[4],
        'dx' => array[5],
        's'  => array[6],
      }
    end

    def load_from_cookie(cookie) # :nodoc:
      begin
        msgpack = GlobalSession::Encoding::Base64Cookie.load(cookie)
        array = GlobalSession::Encoding::Msgpack.load(msgpack)
        hash = attribute_array_to_hash(array)
      rescue Exception => e
        mc = GlobalSession::MalformedCookie.new("Caused by #{e.class.name}: #{e.message}", cookie)
        mc.set_backtrace(e.backtrace)
        raise mc
      end

      id = hash['id']
      authority = hash['a']
      created_at = Time.at(hash['tc'].to_i).utc
      expired_at = Time.at(hash['te'].to_i).utc
      signed = hash['ds']
      insecure = hash.delete('dx')
      signature = hash.delete('s')

      #Check trust in signing authority
      unless @directory.trusted_authority?(authority)
        raise SecurityError, "Global sessions signed by #{authority.inspect} are not trusted"
      end

      signed_hash = RightSupport::Crypto::SignedHash.new(
          hash.reject { |k,v| ['dx', 's'].include?(k) },
          :encoding=>GlobalSession::Encoding::Msgpack,
          :public_key=>@directory.authorities[authority])

      begin
        signed_hash.verify!(signature, expired_at)
      rescue RightSupport::Crypto::ExpiredSignature
        raise GlobalSession::ExpiredSession, "Session expired at #{expired_at}"
      rescue RightSupport::Crypto::InvalidSignature => e
        raise SecurityError, "Global session signature verification failed: " + e.message
      end

      #Check other validity (delegate to directory)
      unless @directory.valid_session?(id, expired_at)
        raise GlobalSession::InvalidSession, "Global session has been invalidated"
      end

      #If all validation stuff passed, assign our instance variables.
      @id = id
      @authority = authority
      @created_at = created_at
      @expired_at = expired_at
      @signed = signed
      @insecure = insecure
      @signature = signature
      @cookie = cookie
    end

    def create_from_scratch # :nodoc:
      authority_check

      @signed = {}
      @insecure = {}
      @created_at = Time.now.utc
      @authority = @directory.local_authority_name
      @id = RightSupport::Data::UUID.generate
      renew!
    end

    def create_invalid # :nodoc:
      @id = nil
      @created_at = Time.now.utc
      @expired_at = created_at
      @signed = {}
      @insecure = {}
      @authority = nil
    end
  end
end
