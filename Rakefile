# -*-ruby-*-
require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/clean'
require 'cucumber/rake/task'

desc "Run unit tests"
task :default => :spec

desc "Run unit tests"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = Dir['**/*_spec.rb']
  t.spec_opts = lambda do
    IO.readlines(File.join(File.dirname(__FILE__), 'spec', 'spec.opts')).map {|l| l.chomp.split " "}.flatten
  end
end

desc 'Generate documentation for the global_session plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'global_session'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Build global_session gem"
Rake::GemPackageTask.new(Gem::Specification.load("global_session.gemspec")) do |package|
  package.need_zip = true
  package.need_tar = true
end

desc "run functional tests"
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--tags ~@slow --color --format pretty}
end

namespace :cucumber do
  desc "Prepare environment to test"
  task :prepare do
    ['2.3.5', '2.3.8'].each do |version|
      puts "Prepare environment for rails #{version}"
      ENV['RAILS_VERSION'] = version
      system('bundle install > /dev/null')
    end
  end
end

CLEAN.include('pkg')
