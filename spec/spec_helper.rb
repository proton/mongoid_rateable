$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")

require "rubygems"
require "mongoid"
require "mongoid_rateable"
require "rspec"
require "database_cleaner"

Dir["#{File.dirname(__FILE__)}/models/*.rb"].each { |f| require f }

Mongoid.config.master = Mongo::Connection.new.db("mongoid_rateable_test")
Mongoid.logger = Logger.new($stdout)

DatabaseCleaner.orm = "mongoid"

Rspec.configure do |config|
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
