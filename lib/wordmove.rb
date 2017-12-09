require 'English'

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
require 'kwalify'

require 'photocopier'

require 'wordmove/exceptions'
require 'wordmove/cli'
require 'wordmove/doctor'
require 'wordmove/doctor/movefile'
require 'wordmove/doctor/mysql'
require 'wordmove/doctor/wpcli'
require 'wordmove/doctor/rsync'
require 'wordmove/logger'
require 'wordmove/movefile'
require 'wordmove/sql_adapter/default'
require 'wordmove/sql_adapter/wpcli'
require "wordmove/version"
require 'wordmove/wordpress_directory'

require 'wordmove/generators/movefile_adapter'
require 'wordmove/generators/movefile'

require 'wordmove/deployer/base'
require 'wordmove/deployer/ftp'
require 'wordmove/deployer/ssh'
require 'wordmove/deployer/ssh/default_sql_adapter'
require 'wordmove/deployer/ssh/wpcli_sql_adapter'

module Wordmove
end
