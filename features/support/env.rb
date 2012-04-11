#--
# Copyright: Copyright (c) 2010 RightScale, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rubygems'
require 'bundler/setup'

require 'tempfile'
require 'shellwords'
require 'thread'

#for String#to_const and other utility stuff
# require 'right_support'

$basedir = File.expand_path('../../..', __FILE__)
$libdir  = File.join($basedir, 'lib')
require File.join($libdir, 'global_session')

class RightRailsTestWorld
  class ShellCommandFailed < Exception; end

  def initialize
    @app_console_mutex = Mutex.new
  end

  def scenario_state
    @scenario_state ||= OpenStruct.new
  end

  # Return the app's RAILS_ROOT (shared across all scenarios/features in a given run!)
  def app_root
    @@app_root ||= Dir.mktmpdir('global_session')

    unless File.directory?(@@app_root)
      FileUtils.mkdir_p(@@app_root)
      at_exit do
        FileUtils.rm_rf(@@app_root)
      end
    end

    @@app_root
  end

  # Construct a path relative to the app's RAILS_ROOT
  def app_path(*relative)
    File.join(app_root, *relative)
  end

  # Give the app's database name (shared across all scenarios/features in a given run!)
  def app_db_name
    @@database_name ||= "temp_global_session_#{Time.now.to_i}"
    @@database_name
  end

  # Run a shell command in app_dir, e.g. a rake task
  def app_shell(cmd, options={})
    ignore_errors = options[:ignore_errors] || false
    log = !!(Cucumber.logger)

    Cucumber.logger.debug("bash> #{cmd}\n") if log

    Dir.chdir(app_root) do
      IO.popen("#{cmd} 2>&1", 'r') do |output|
        output.sync = true
        done = false
        while !done
          begin
            Cucumber.logger.debug(output.readline + "\n") if log
          rescue EOFError
            done = true
          end
        end
      end
    end

    $?.success?.should(be_true) unless ignore_errors
  end

  MAX_CONSOLE_TIME = 60.0

  # Run a console command using script/console
  def app_console(cmd, options={})
    repeat = options[:repeat] || 1
    thing_to_return = options[:return] || :output
    app_console = nil

    if options[:detach]
      Dir.chdir(app_root) do
        app_console = IO.popen('script/console', 'r+')
      end
    else
      @app_console_mutex.synchronize do
        unless @app_console
          Dir.chdir(app_root) do
            @app_console = IO.popen('script/console', 'r+')
          end
        end
        app_console = @app_console
      end
    end

    t0   = Time.now.to_f
    app_console.puts 'result = begin'
    repeat.times do
      app_console.puts cmd
    end
    app_console.puts 'rescue Exception => e'
    app_console.puts 'puts "--OH NOES-- - #{e.class.name} - #{e.message}"'
    app_console.puts 'end'
    app_console.puts 'puts "--KTHXBYE-- #{result.inspect}"'
    app_console.puts 'quit' if options[:detach]

    Cucumber.logger.debug("irb> #{cmd}")

    done = false

    output = []

    while (Time.now.to_f - t0) < MAX_CONSOLE_TIME && !done
      line = app_console.readline
      if line =~ /^--OH NOES--/
        error = line.gsub('--OH NOES-- - ', '').chomp
      elsif line =~ /^--KTHXBYE--/
        result = line.split(' ', 2).second.chomp
        done = true
      else
        output << line
        Cucumber.logger.debug(line)
      end
    end

    (Time.now.to_f - t0).should(be <= MAX_CONSOLE_TIME)

    if options[:expect].is_a?(Class) && options[:expect].ancestors.include?(Exception)
      error.should =~ Regexp.new("^#{Regexp.escape(options[:expect].name)} -")
    elsif !options[:ignore_errors]
      error.should(be_nil) unless options[:ignore_errors]
    end

    case options[:expect]
      when String
        result.should == options[:expect]
      when Regexp
        result.should =~ options[:expect]
      when NilClass
        #no expectation
    end

    case thing_to_return
      when :output
        return output
      when :result
        return result
      else
        raise ArgumentError, "Unknown :return #{thing_to_return}"
    end
  end

  # Return a Sequel data-access object for the app's database. Can be used to verify
  # expectations about the database's schema or contents, or to inject test data into
  # the database.
  def app_db
    unless @app_db
      @app_db = Sequel.mysql(:host => 'localhost', :user => 'root',
                        :database => app_db_name, :password => nil)
      #cannot aggregate to Cucumber logger because Sequel is too noisy with INFO level
      #@app_db.logger = Cucumber.logger
    end

    @app_db
  end

  # Find the next available serial number for a migration in the test app
  def next_migration_version
    migrations_dir = app_path('db', 'migrate')
    FileUtils.mkdir_p(migrations_dir)
    existing_versions = Dir[File.join(migrations_dir, '*.rb')].map { |p| Integer(File.basename(p).split('_', 2).first) }
    (existing_versions.max || 0) + 1
  end
end

World do
  RightRailsTestWorld.new
end

After do
  app_shell('rake db:drop', :ignore_errors=>true)
end
