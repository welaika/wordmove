require 'thor'
require 'wordmove/generators/movefile'
require 'wordmove/deployer'


module Wordmove
  class CLI < Thor

    desc "init", "Generates a brand new Movefile"
    def init
      Wordmove::Generators::Movefile.start
    end

    desc "pull", "Pulls WP data from remote host to the local machine"
    method_option :skip_db,       :aliases => "-d", :type => :boolean
    method_option :adapt_sql,     :aliases => "-a", :type => :boolean
    method_option :skip_uploads,  :aliases => "-u", :type => :boolean
    method_option :skip_themes,   :aliases => "-t", :type => :boolean
    method_option :skip_plugins,  :aliases => "-p", :type => :boolean
    method_option :verbose,       :aliases => "-v", :type => :boolean
    method_option :config,        :aliases => "-c"
    def pull
      deployer = Wordmove::Deployer.new(options)
      deployer.pull
    end

    desc "push", "Pushes WP data from local machine to remote host"
    method_option :skip_db,       :aliases => "-d", :type => :boolean
    method_option :adapt_sql,     :aliases => "-a", :type => :boolean
    method_option :skip_uploads,  :aliases => "-u", :type => :boolean
    method_option :skip_themes,   :aliases => "-t", :type => :boolean
    method_option :skip_plugins,  :aliases => "-p", :type => :boolean
    method_option :verbose,       :aliases => "-v", :type => :boolean
    method_option :config,        :aliases => "-c"
    def push
      deployer = Wordmove::Deployer.new(options)
      deployer.push
    end

  end
end
