require 'thor'
require 'wordmove/generators/movefile'
require 'wordmove/deployer/base'

module Wordmove
  class CLI < Thor

    desc "init", "Generates a brand new Movefile"
    def init
      Wordmove::Generators::Movefile.start
    end

    shared_options = {
      :wordpress   => { :aliases => "-w", :type => :boolean },
      :uploads     => { :aliases => "-u", :type => :boolean },
      :themes      => { :aliases => "-t", :type => :boolean },
      :plugins     => { :aliases => "-p", :type => :boolean },
      :languages   => { :aliases => "-l", :type => :boolean },
      :db          => { :aliases => "-d", :type => :boolean },

      :verbose     => { :aliases => "-v", :type => :boolean },
      :simulate    => { :aliases => "-s", :type => :boolean },
      :environment => { :aliases => "-e"                    },
      :config      => { :aliases => "-c"                    },

      :no_adapt    => { :type => :boolean                   },
      :all         => { :type => :boolean                   }
    }

    no_tasks do
      def handle_options(options)
        %w(wordpress uploads themes plugins languages db).map(&:to_sym).each do |task|
          if options[task] || options[:all]
            yield task
          end
        end
      end
    end

    desc "pull", "Pulls WP data from remote host to the local machine"
    shared_options.each do |option, args|
      method_option option, args
    end
    def pull
      deployer = Wordmove::Deployer::Base.deployer_for(options)
      handle_options(options) do |task|
        deployer.send("pull_#{task}")
      end
    end

    desc "push", "Pushes WP data from local machine to remote host"
    shared_options.each do |option, args|
      method_option option, args
    end
    def push
      deployer = Wordmove::Deployer::Base.deployer_for(options)
      handle_options(options) do |task|
        deployer.send("push_#{task}")
      end
    end

  end
end
