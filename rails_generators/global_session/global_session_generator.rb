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

class GlobalSessionGenerator < Rails::Generator::Base
  def initialize(runtime_args, runtime_options = {})
    super

    @app_name   = File.basename(::Rails.root)
    @app_domain = args.shift
    raise ArgumentError, "Must specify DNS domain for global session cookie, e.g. 'example.com'" unless @app_domain
  end

  def manifest
    record do |m|
      
      m.template 'global_session.yml.erb',
                 'config/global_session.yml',
                 :assigns=>{:app_name=>@app_name,
                            :app_domain=>@app_domain}

      puts "*** IMPORTANT - WORK IS REQUIRED ***"
      puts "In order to make use of the global session, you will need to ensure that it"
      puts "is installed to the Rack middleware stack. You can do so by adding an extra"
      puts "line in your environment.rb inside the Rails initializer block, like so:"
      puts
      puts "         Rails::Initializer.run do |config|"
      puts "ADD>>      require 'global_session'"
      puts "ADD>>      GlobalSession::Rails.activate(config)"
      puts "         end"

    end
  end
end
