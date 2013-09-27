# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{global_session}
  s.version = "2.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tony Spataro"]
  s.date = %q{2013-09-23}
  s.description = %q{This Rack middleware allows several web apps in an authentication domain to share session state, facilitating single sign-on in a distributed web app. It only provides session sharing and does not concern itself with authentication or replication of the user database.}
  s.email = %q{support@rightscale.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "CHANGELOG.rdoc",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "global_session.gemspec",
    "init.rb",
    "lib/global_session.rb",
    "lib/global_session/configuration.rb",
    "lib/global_session/directory.rb",
    "lib/global_session/encoding.rb",
    "lib/global_session/rack.rb",
    "lib/global_session/rails.rb",
    "lib/global_session/rails/action_controller_class_methods.rb",
    "lib/global_session/rails/action_controller_instance_methods.rb",
    "lib/global_session/session.rb",
    "lib/global_session/session/abstract.rb",
    "lib/global_session/session/v1.rb",
    "lib/global_session/session/v2.rb",
    "rails/init.rb",
    "rails_generators/global_session/USAGE",
    "rails_generators/global_session/global_session_generator.rb",
    "rails_generators/global_session/templates/global_session.yml.erb",
    "rails_generators/global_session_authority/USAGE",
    "rails_generators/global_session_authority/global_session_authority_generator.rb"
  ]
  s.homepage = %q{https://github.com/rightscale/global_session}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Secure single-domain session sharing plugin for Rack and Rails.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<right_support>, ["~> 2.5"])
      s.add_runtime_dependency(%q<simple_uuid>, [">= 0.2.0"])
      s.add_runtime_dependency(%q<json>, ["~> 1.4"])
      s.add_runtime_dependency(%q<msgpack>, ["~> 0.4"])
      s.add_runtime_dependency(%q<rack-contrib>, ["~> 1.0"])
      s.add_development_dependency(%q<rake>, ["~> 0.8"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3"])
      s.add_development_dependency(%q<cucumber>, ["~> 1.0"])
      s.add_development_dependency(%q<right_develop>, ["~> 1.2"])
      s.add_development_dependency(%q<flexmock>, ["~> 0.8"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.3"])
      s.add_development_dependency(%q<httpclient>, [">= 0"])
      s.add_development_dependency(%q<ruby-debug>, ["~> 0.10"])
      s.add_development_dependency(%q<debugger>, ["~> 1.5"])
    else
      s.add_dependency(%q<right_support>, ["~> 2.5"])
      s.add_dependency(%q<simple_uuid>, [">= 0.2.0"])
      s.add_dependency(%q<json>, ["~> 1.4"])
      s.add_dependency(%q<msgpack>, ["~> 0.4"])
      s.add_dependency(%q<rack-contrib>, ["~> 1.0"])
      s.add_dependency(%q<rake>, ["~> 0.8"])
      s.add_dependency(%q<rspec>, ["~> 1.3"])
      s.add_dependency(%q<cucumber>, ["~> 1.0"])
      s.add_dependency(%q<right_develop>, ["~> 1.2"])
      s.add_dependency(%q<flexmock>, ["~> 0.8"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
      s.add_dependency(%q<httpclient>, [">= 0"])
      s.add_dependency(%q<ruby-debug>, ["~> 0.10"])
      s.add_dependency(%q<debugger>, ["~> 1.5"])
    end
  else
    s.add_dependency(%q<right_support>, ["~> 2.5"])
    s.add_dependency(%q<simple_uuid>, [">= 0.2.0"])
    s.add_dependency(%q<json>, ["~> 1.4"])
    s.add_dependency(%q<msgpack>, ["~> 0.4"])
    s.add_dependency(%q<rack-contrib>, ["~> 1.0"])
    s.add_dependency(%q<rake>, ["~> 0.8"])
    s.add_dependency(%q<rspec>, ["~> 1.3"])
    s.add_dependency(%q<cucumber>, ["~> 1.0"])
    s.add_dependency(%q<right_develop>, ["~> 1.2"])
    s.add_dependency(%q<flexmock>, ["~> 0.8"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
    s.add_dependency(%q<httpclient>, [">= 0"])
    s.add_dependency(%q<ruby-debug>, ["~> 0.10"])
    s.add_dependency(%q<debugger>, ["~> 1.5"])
  end
end

