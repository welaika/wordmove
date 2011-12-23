require 'rubygems'
require 'bundler/setup'

require 'wordmove' # and any other gems you need
require 'hashie'
require 'wordmove/hosts/local_host'
require 'wordmove/hosts/remote_host'
require 'wordmove/logger'
require 'tempfile'
require 'active_support/core_ext'
require 'thor'

RSpec.configure do |config|
  # some (optional) config here
end
