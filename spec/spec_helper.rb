$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

MODELS = File.join(File.dirname(__FILE__), 'models')

require 'rubygems'
require 'mongoid'
require 'mongoid_rateable'
require 'simplecov'
require 'database_cleaner'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])
SimpleCov.start

Mongoid.configure do |config|
  config.connect_to "mongoid_rateable_test"
end

Mongoid.logger = Logger.new($stdout)

if Mongoid::VERSION>'5'
  Mongo::Logger.logger.level = ::Logger::FATAL
end

Dir["#{MODELS}/*.rb"].each { |f| require f }

DatabaseCleaner.orm = "mongoid"

RSpec.configure do |config|
  config.before(:all) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end