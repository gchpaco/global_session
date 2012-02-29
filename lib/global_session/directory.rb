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

require 'set'

module GlobalSession
  # The global session directory, which provides some lookup and decision services
  # to instances of Session.
  #
  # The default implementation is simplistic, but should be suitable for most applications.
  # Directory is designed to be specialized via subclassing. To override the behavior to
  # suit your needs, simply create a subclass of Directory and add a configuration file
  # setting to specify the class name of your implementation:  
  #
  #     common:
  #       directory: MyCoolDirectory
  #
  #
  # === The Authority Keystore
  # Directory uses a filesystem directory as a backing store for RSA
  # public keys of global session authorities. The directory should
  # contain one or more +*.pub+ files containing OpenSSH-format public
  # RSA keys. The name of the pub file determines the name of the
  # authority it represents.
  #
  # === The Local Authority
  # Directory will infer the name of the local authority (if any) by
  # looking for a private-key file in the keystore. If a +*.key+ file
  # is found, then its name is taken to be the name of the local
  # authority and all GlobalSessions created will be signed by that
  # authority's private key.
  #
  # If more than one key file is found, Directory will raise an error
  # at initialization time.
  #
  class Directory
    attr_reader :configuration, :authorities, :private_key

    # Create a new Directory.
    #
    # === Parameters
    # keystore_directory(String):: Absolute path to authority keystore
    #
    # ===Raise
    # ConfigurationError:: if too many or too few keys are found, or if *.key/*.pub files are malformatted
    def initialize(configuration, keystore_directory)
      @configuration = configuration
      certs = Dir[File.join(keystore_directory, '*.pub')]
      keys  = Dir[File.join(keystore_directory, '*.key')]

      @authorities = {}
      certs.each do |cert_file|
        basename = File.basename(cert_file)
        authority = basename[0...(basename.rindex('.'))] #chop trailing .ext
        @authorities[authority] = OpenSSL::PKey::RSA.new(File.read(cert_file))
        raise ConfigurationError, "Expected #{basename} to contain an RSA public key" unless @authorities[authority].public?
      end

      if local_authority_name
        key_file = keys.detect { |kf| kf =~ /#{local_authority_name}.key$/ }
        raise ConfigurationError, "Key file #{local_authority_name}.key not found" unless key_file        
        @private_key  = OpenSSL::PKey::RSA.new(File.read(key_file))
        raise ConfigurationError, "Expected #{key_file} to contain an RSA private key" unless @private_key.private?
      end

      @invalid_sessions = Set.new
    end

    def local_authority_name
      @configuration['authority']
    end
    
    # Determine whether this system trusts a particular authority based on
    # the trust settings specified in Configuration.
    #
    # === Parameters
    # authority(String):: The name of the authority
    #
    # === Return
    # trusted(true|false):: whether the local system trusts sessions signed by the specified authority
    def trusted_authority?(authority)
      @configuration['trust'].include?(authority)
    end

    # Determine whether the given session UUID is valid. The default implementation only considers
    # a session to be invalid if its expired_at timestamp is in the past. Custom implementations
    # might want to consider other factors, such as whether the user has signed out of this node
    # or another node (perhaps using some sort of centralized lookup or single sign-out mechanism).
    #
    # === Parameters
    # uuid(String):: Global session UUID
    # expired_at(Time):: When the session expired (or will expire)
    #
    # === Return
    # valid(true|false):: whether the specified session is valid
    def valid_session?(uuid, expired_at)
      (expired_at > Time.now) && !@invalid_sessions.include?(uuid)
    end

    # Callback used by Session objects to report when the application code calls
    # #invalidate! on them. The default implementation of this method records
    # invalid session IDs using an in-memory data structure, which is not ideal
    # for most implementations.
    #
    # uuid(String):: Global session UUID
    # expired_at(Time):: When the session expired
    #
    # === Return
    # true:: Always returns true
    def report_invalid_session(uuid, expired_at)
      @invalid_sessions << uuid
    end
  end  
end