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
  # Helper class that enables the end user to treat the global and local session as if
  # they were the same object. This is accomplished by implementing approximately the
  # same interface as a Hash, and dispatching to one or the other session object depending
  # on various factors.
  #
  # This class isn't intended to be used directly by the end user. Instead, set integrated: true
  # in the configuration file and the Web framework integration code will manage an integrated
  # session object for you, as well as overriding the framework's default session accessor to
  # return an integrated session instead.
  #
  # When using an integrated session, you can always get to the underlying objects by
  # using the #local and #global readers of this class.
  #
  class GlobalSession::IntegratedSession
    # Return the local-session objects, whose type may vary depending on the Web framework.
    attr_reader :local

    # Return the global-session object.
    attr_reader :global
    
    # Construct a new integrated session.
    #
    # === Parameters
    # local(Object):: Local session that acts like a Hash
    # global(Session):: Session
    def initialize(local, global)
      @local = local
      @global = global
    end

    # Retrieve a value from the global session if the supplied key is supported by
    # the global session, else retrieve it from the local session.
    #
    # === Parameters
    # key(String):: the key
    #
    # === Return
    # value(Object):: The value associated with +key+, or nil if +key+ is not present
    def [](key)
      key = key.to_s
      if @global.supports_key?(key)
        @global[key]
      else
        @local[key]
      end
    end

    # Set a value in the global session (if the supplied key is supported) or the local
    # session otherwise.
    #
    # === Parameters
    # key(String):: The key to set
    # value(Object):: The value to set
    #
    # === Return
    # value(Object):: Always returns the value that was set
    def []=(key, value)
      key = key.to_s
      if @global.supports_key?(key)
        @global[key] = value
      else
        @local[key] = value
      end

      return value
    end

    # Determine whether the global or local session contains a value with the specified key.
    #
    # === Parameters
    # key(String):: The name of the key
    #
    # === Return
    # contained(true|false):: Whether the session currently has a value for the specified key.
    def has_key?(key)
      key = key.to_s
      @global.has_key?(key) || @local.has_key?(key)
    end

    alias :key? :has_key?
    
    # Return the keys that are currently present in either the global or local session.
    #
    # === Return
    # keys(Array):: List of keys contained in the global or local session.
    def keys
      @global.keys + @local.keys
    end

    # Return the values that are currently present in the global or local session.
    #
    # === Return
    # values(Array):: List of values contained in the global or local session.
    def values
      @global.values + @local.values
    end

    # Iterate over each key/value pair in both the global and local session.
    #
    # === Block
    # An iterator which will be called with each key/value pair
    #
    # === Return
    # Returns the value of the last expression evaluated by the block
    def each_pair(&block)
      @global.each_pair(&block)
      @local.each_pair(&block)
    end

    def respond_to?(meth) # :nodoc:
      return @global.respond_to?(meth) || @local.respond_to?(meth) || super
    end
    
    def method_missing(meth, *args) # :nodoc:
      if @global.respond_to?(meth)
        @global.__send__(meth, *args)
      elsif @local.respond_to?(meth)
        @local.__send__(meth, *args)
      else
        super
      end
    end
  end
end