source "http://rubygems.org"
gemspec

group :development do
  gem 'rake',              '~> 0.8'
  gem 'ruby-debug',        '~> 0.10'
  gem 'rspec',             '~> 1.3'
  gem 'flexmock',          '~> 0.8'
  gem 'httpclient'
  gem 'rack',              '~>1.1.0'

  # In case we're going to support different Rails versions
  unless defined?(ENV['RAILS_VERSION'])
    # Use a fork of ActionPack 2.3.5 in order to prevent idiotic Rack bug
    gem 'actionpack', '2.3.5', :git=> 'git://github.com/xeger/actionpack.git'
    gem 'rails', '2.3.5'
  else
    case(ENV['RAILS_VERSION'])
      when('2.3.5')
        gem 'actionpack', '2.3.5', :git=> 'git://github.com/xeger/actionpack.git'
        gem 'rails', '2.3.5'
      when('2.3.8')
        gem 'rails', '2.3.8'
      else
        raise "Use 'export RAILS_VERSION' to set correct version of Rails you want to use!"
    end
  end
end

group :cucumber do
  gem 'cucumber', "~> 0.8"
  gem 'mysql'
  gem 'sqlite3'
  gem 'sequel', '3.0.0'

end

