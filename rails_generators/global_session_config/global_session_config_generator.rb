class GlobalSessionConfigGenerator < Rails::Generator::Base
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
    end
  end
end
