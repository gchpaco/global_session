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
  case(ENV['RAILS_VERSION'])
    when('2.3.8')
      gem 'rails', '2.3.8'
    else
      gem 'actionpack', '2.3.5', :git=> 'git://github.com/xeger/actionpack.git'
      gem 'rails', '2.3.5'
  end
end

group :cucumber do
  gem 'cucumber', "~> 0.8"
  gem 'mysql'
  gem 'sqlite3'
  gem 'sequel', '3.0.0'

end

