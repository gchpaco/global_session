Given /^a Rails app$/ do
  if File.directory?(app_path('.git'))
    #stage all changes so we can wipe them out
    app_shell('git add .')
    app_shell('git reset --hard initial')
  else
    STDOUT.puts "====> installing rails there #{app_path('')}"
    app_shell("rails . -q")

    config_dir = app_path('config')

    File.open(File.join(config_dir, 'database.yml'), 'w') do |f|
      f.puts "development:"
      f.puts "  adapter: mysql"
      f.puts "  host: localhost"
      f.puts "  database: #{app_db_name}"
      f.puts "  username: root"
      f.puts "  password:"
    end

    File.open(File.join(config_dir, 'environment.rb'), 'w') do |f|

      f.puts <<TEXT
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')
require 'global_session'

Rails::Initializer.run do |config|
  config.gem 'global_session'
  config.time_zone = 'UTC'
end
TEXT
    end

    app_shell('git init')
    app_shell('git add .')
    app_shell('git commit -q -m "Initial commit"')
    app_shell('git tag initial')
  end

  app_shell('rake db:drop', :ignore_errors=>true)
  app_shell('rake db:create')
end

Given /^global_session is configured correctly$/ do
  config_dir = app_path('config')
  initializers_dir  = File.join(config_dir, 'initializers')

  app_shell('./script/generate global_session_authority development')
  app_shell('./script/generate global_session localhost')

  File.open(File.join(config_dir, 'environment.rb'), 'w') do |f|
    f.puts <<TEXT
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')
require 'global_session'

Rails::Initializer.run do |config|
  config.gem 'global_session'
  GlobalSession::Rails.activate(config)
  config.time_zone = 'UTC'
end
TEXT
  end

  File.open(File.join(initializers_dir, 'session_store.rb'), 'w') do |f|
    f.puts <<TEXT
ActionController::Base.session = { 
  :key         => '_global_session20120411-89611-1qxgklm_session',
  :secret      => 'f9459ef5b24e84afeae24599913fb10d77ad90bd0207f86ecdc23d619d8e411de6f3029f412990b6a55852dcbe2aa4030c4e41f2a8783562f51124617fdfb341'
}
ActionController::Base.session_store = :active_record_store
TEXT
  end

  app_shell('rake db:sessions:create > foo')
  app_shell('rake db:migrate')
end

Given /^I have my application running$/ do
  run_app
end
