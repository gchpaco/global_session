source "http://rubygems.org"

group :development do
  gem 'rake',              '~> 0.8'
  gem 'ruby-debug',        '~> 0.10'
  gem 'rspec',             '~> 1.3'
  gem 'flexmock',          '~> 0.8'

  #Use a fork of ActionPack 2.3.5 in order to prevent idiotic Rack bug
  gem 'actionpack',        '2.3.5', :git=>'git://github.com/xeger/actionpack.git',
                                    :branch=>'master'
end

gemspec
