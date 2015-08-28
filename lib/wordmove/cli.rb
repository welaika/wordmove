module Wordmove
  class CLI < Thor
    map %w[--version -v] => :__print_version

    desc "--version, -v", "Print the version"
    def __print_version
      puts Wordmove::VERSION
    end

    desc "init", "Generates a brand new Movefile"
    def init
      Wordmove::Generators::Movefile.start
    end

    shared_options = {
      wordpress:   { aliases: "-w", type: :boolean },
      uploads:     { aliases: "-u", type: :boolean },
      themes:      { aliases: "-t", type: :boolean },
      plugins:     { aliases: "-p", type: :boolean },
      mu_plugins:  { aliases: "-m", type: :boolean },
      languages:   { aliases: "-l", type: :boolean },
      db:          { aliases: "-d", type: :boolean },

      verbose:     { aliases: "-v", type: :boolean },
      simulate:    { aliases: "-s", type: :boolean },
      environment: { aliases: "-e" },
      config:      { aliases: "-c" },

      no_adapt:    { type: :boolean },
      all:         { type: :boolean }
    }

    no_tasks do
      def handle_options(options)
        wordpress_options.each do |task|
          yield task if options[task] || options["all"]
        end
      end

      def wordpress_options
        %w(wordpress uploads themes plugins mu_plugins languages db)
      end

      def ensure_wordpress_options_presence!(options)
        return if (options.keys & (wordpress_options + ["all"])).present?
        puts "No options given. See wordmove --help"
        exit 1
      end
    end

    desc "pull", "Pulls WP data from remote host to the local machine"
    shared_options.each do |option, args|
      method_option option, args
    end
    def pull
      ensure_wordpress_options_presence!(options)
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
      ensure_wordpress_options_presence!(options)
      deployer = Wordmove::Deployer::Base.deployer_for(options)
      handle_options(options) do |task|
        deployer.send("push_#{task}")
      end
    end

  end
end
