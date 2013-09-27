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

class GlobalSessionAuthorityGenerator < Rails::Generator::Base
  def initialize(runtime_args, runtime_options = {})
    super

    @app_name  = File.basename(::Rails.root)
    @auth_name = args.shift
    raise ArgumentError, "Must specify name for global session authority, e.g. 'prod'" unless @auth_name
  end

  def manifest
    record do |m|
      new_key     = OpenSSL::PKey::RSA.generate( 1024 )
      new_public  = new_key.public_key.to_pem
      new_private = new_key.to_pem

      dest_dir = File.join(::Rails.root, 'config', 'authorities')
      FileUtils.mkdir_p(dest_dir)

      File.open(File.join(dest_dir, @auth_name + ".pub"), 'w') do |f|
        f.puts new_public
      end

      File.open(File.join(dest_dir, @auth_name + ".key"), 'w') do |f|
        f.puts new_private
      end

      puts "***"
      puts "*** Don't forget to delete config/authorities/#{@auth_name}.key"
      puts "***"
    end
  end
end
