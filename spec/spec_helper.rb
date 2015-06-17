$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mongokit'
require 'database_cleaner'

SPEC_DIR = File.expand_path(File.dirname(__FILE__))

Mongoid.load!("#{SPEC_DIR}/fixtures/mongoid.yml", :production)

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

def fixture_file(name)
  "#{SPEC_DIR}/fixtures/#{name}"
end

class DynamicCollectionCounter
  def self.next
    @counter ||= 0
    @counter += 1
  end
end

def new_model(*modules)
  Class.new do
    include Mongoid::Document

    store_in collection: "mkcollection_#{DynamicCollectionCounter.next}"
    mongokit(*modules) if modules.any?

    def self.field_names
      fields.keys
    end
  end
end

