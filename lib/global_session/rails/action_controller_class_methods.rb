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
  module Rails
    # Module that is mixed into ActionController's eigenclass; provides access to shared
    # app-wide data such as the configuration object, and implements the DSL used to
    # configure controllers' use of the global session.
    module ActionControllerClassMethods
      VALID_OPTIONS = [:integrated, :raise, :renew, :only, :except]
      DEFAULT_OPTIONS = {
        :integrated=>false,
        :raise=>true,
        :renew=>true
      }

      def has_global_session(options={})
        #validate our options
        options.assert_valid_keys(VALID_OPTIONS)
        if options.key?(:only) && options.key?(:except)
          raise ArgumentError, "Must specify :only OR :except, you specified both"
        end

        #start with default options; merge any options inherited from our base class;
        #merge any options provided by the caller.
        obase   = self.superclass.global_session_options
        options = DEFAULT_OPTIONS.merge(obase).merge(options)

        #ensure derived-class options don't conflict with mutually exclusive base-class options
        options.delete(:only) if obase.has_key?(:only) && options.has_key?(:except)
        options.delete(:except) if obase.has_key?(:except) && options.has_key?(:only)

        #mark the global session as enabled (a hidden option) and store our
        #calculated, merged options
        options[:enabled] = true

        self.global_session_options = options
      end

      def no_global_session
        #mark the global session as not-enabled (a hidden option)
        self.global_session_options={:enabled=>false}
      end

      def global_session_options
        if @global_session_options
          @global_session_options
        elsif self.superclass.respond_to?(:global_session_options)
          self.superclass.global_session_options
        else
          {}
        end
      end

      def global_session_options=(options)
        @global_session_options = options
      end      
    end
  end
end