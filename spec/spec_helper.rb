$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "pry-byebug"
require "wordmove"
require 'wordmove/logger'
require 'active_support/all'
require 'thor'

Dir[File.expand_path("../support/**/*.rb", __FILE__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
