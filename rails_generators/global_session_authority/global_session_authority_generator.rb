class GlobalSessionAuthorityGenerator < Rails::Generator::Base
  def initialize(runtime_args, runtime_options = {})
    super

    @app_name  = File.basename(::Rails.root)
    @auth_name = args.shift
    raise ArgumentError, "Must specify name for global session authority, e.g. 'mycoolapp'" unless @auth_name
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
