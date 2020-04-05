require 'English'

require 'active_support'
require 'active_support/core_ext'
require 'colorize'
require 'dotenv'
require 'dry-configurable'
require 'erb'
require 'kwalify'
require 'light-service'
require 'logger'
require 'open-uri'
require 'ostruct'
require 'thor'
require 'thor/group'
require 'yaml'

require 'photocopier'

require 'wordmove/cli'
require 'wordmove/doctor'
require 'wordmove/doctor/movefile'
require 'wordmove/doctor/mysql'
require 'wordmove/doctor/rsync'
require 'wordmove/doctor/ssh'
require 'wordmove/doctor/wpcli'
require 'wordmove/exceptions'
require 'wordmove/guardian'
require 'wordmove/hook'
require 'wordmove/logger'
require 'wordmove/movefile'
require 'wordmove/wordpress_directory'
require 'wordmove/version'
require 'wordmove/environments_list'

require 'wordmove/generators/movefile_adapter'
require 'wordmove/generators/movefile'

require 'wordmove/db_paths_config'

require 'wordmove/actions/helpers'
require 'wordmove/actions/ssh/helpers'
Dir[File.join(__dir__, 'wordmove/actions/**/*.rb')].sort.each { |file| require file }

module Wordmove
  # Interactors' namespce. Interactors are called "Actions", following the LightService convention.
  # In this namespace there are two kinds of "Actions":
  # * local environment actions
  # * protocol agnostic remote environment actions
  # @see https://github.com/adomokos/light-service/blob/master/README.md LightService README
  module Actions
    # Ssh actions' namespace. Here are SSH protocol specific actions and organizers
    # for remote environments
    module Ssh
    end
  end
end
