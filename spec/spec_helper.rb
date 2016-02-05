$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "tempfile"
require "pry-byebug"
require "priscilla"

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "wordmove"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "./spec/examples.txt"
end
