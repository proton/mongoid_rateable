$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

MODELS = File.join(File.dirname(__FILE__), 'models')

require 'rubygems'
require 'mongoid'
require 'mongoid_rateable'
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

if Mongoid::VERSION.start_with? '5'
  Mongo::Logger.logger.level = ::Logger::FATAL
elsif Mongoid::VERSION.start_with? '4'
  Moped.logger = nil
end

require_relative 'support/database_cleaner'

Dir["#{MODELS}/*.rb"].each { |f| require f }

Mongoid.configure do |config|
  config.connect_to 'mongoid_rateable_test'
end

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean
  end
end
