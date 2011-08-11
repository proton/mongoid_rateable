# encoding: utf-8

require 'rubygems'
require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mongoid_rateable"
  gem.homepage = "http://github.com/proton/mongoid_rateable"
  gem.license = "MIT"
  gem.summary = %q{Rating functionality for Mongoid documents}
  gem.description = %q{Provides fields and methods for the rating manipulation on Mongoid documents.}
  gem.email = "psavichev@gmail.com"
  gem.authors = ["Peter Savichev (proton)"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongoid_rateable #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Build gem"
task :build do
	puts "Regenerating gemspec"
  system "rake gemspec"
	puts "Building"
  system "gem build mongoid_rateable.gemspec"
end

desc "Release gem"
task :release => :build do
	version = File.exist?('VERSION') ? File.read('VERSION') : ""

#	puts "Commiting #{version}"
#	system "git commit -a -m 'Version bump to #{version}'"
#  puts "Tagging #{version}"
#  system "git tag -a #{version} -m 'Tagging #{version}'"
#	puts "Pushing…"
#  system "git push"
#  system "git push --tags"
#  puts "Releasing to Gemcutter"
#  system "gem push mongoid_rateable-#{version}.gem"
end

