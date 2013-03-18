require 'thor'
require 'wordmove/generators/movefile'
require 'wordmove/deployer/base'

module Wordmove
  class CLI < Thor

    desc "init", "Generates a brand new Movefile"
    def init
      Wordmove::Generators::Movefile.start
    end

    desc "pull", "Pulls WP data from remote host to the local machine"
    method_option :db,       :aliases => "-d", :type => :boolean
    method_option :uploads,  :aliases => "-u", :type => :boolean
    method_option :themes,   :aliases => "-t", :type => :boolean
    method_option :plugins,  :aliases => "-p", :type => :boolean
    method_option :verbose,  :aliases => "-v", :type => :boolean
    method_option :simulate, :aliases => "-s", :type => :boolean
    method_option :no_adapt, :type => :boolean
    method_option :config,   :aliases => "-c"
    def pull
      deployer = Wordmove::Deployer::Base.deployer_for(options)
      %w(db uploads themes plugins).map(&:to_sym).each do |task|
        if options[task]
          deployer.send("pull_#{task}")
        end
      end
    end

    desc "push", "Pushes WP data from local machine to remote host"
    method_option :db,       :aliases => "-d", :type => :boolean
    method_option :uploads,  :aliases => "-u", :type => :boolean
    method_option :themes,   :aliases => "-t", :type => :boolean
    method_option :plugins,  :aliases => "-p", :type => :boolean
    method_option :verbose,  :aliases => "-v", :type => :boolean
    method_option :simulate, :aliases => "-s", :type => :boolean
    method_option :no_adapt, :type => :boolean
    method_option :config,   :aliases => "-c"
    def push
      deployer = Wordmove::Deployer::Base.deployer_for(options)
      %w(db uploads themes plugins).map(&:to_sym).each do |task|
        if options[task]
          deployer.send("push_#{task}")
        end
      end
    end

  end
end
