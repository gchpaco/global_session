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
