require 'thor'
require 'thor/group'
require 'colorize'
require 'logger'
require 'yaml'
require 'ostruct'
require 'erb'
require 'open-uri'
require 'active_support'
require 'active_support/core_ext'

require 'photocopier'

require 'wordmove/exceptions'
require 'wordmove/cli'
require 'wordmove/logger'
require 'wordmove/sql_adapter'
require "wordmove/version"
require 'wordmove/wordpress_directory'

require 'wordmove/generators/movefile_adapter'
require 'wordmove/generators/movefile'

require 'wordmove/deployer/base'
require 'wordmove/deployer/ftp'
require 'wordmove/deployer/ssh'

module Wordmove
end
