module Wordmove
  class CLI < Thor
    map %w[--version -v] => :__print_version

    desc "--version, -v", "Print the version"
    def __print_version
      puts Wordmove::VERSION
    end

    desc "init", "Generates a brand new movefile.yml"
    def init
      Wordmove::Generators::Movefile.start
    end

    desc "doctor", "Do some local configuration and environment checks"
    def doctor
      Wordmove::Doctor.start
    rescue Wordmove::MovefileNotFound => e
      logger.error(e.message)
      exit 1
    rescue Psych::SyntaxError => e
      logger.error("Your movefile is not parsable due to a syntax error: #{e.message}")
      exit 1
    end

    shared_options = {
      wordpress: { aliases: "-w", type: :boolean },
      uploads: { aliases: "-u", type: :boolean },
      themes: { aliases: "-t", type: :boolean },
      plugins: { aliases: "-p", type: :boolean },
      mu_plugins: { aliases: "-m", type: :boolean },
      languages: { aliases: "-l", type: :boolean },
      db: { aliases: "-d", type: :boolean },
      verbose: { aliases: "-v", type: :boolean },
      simulate: { aliases: "-s", type: :boolean },
      environment: { aliases: "-e" },
      config: { aliases: "-c" },
      debug: { type: :boolean },
      no_adapt: { type: :boolean },
      all: { type: :boolean }
    }

    no_tasks do
      def handle_options(options)
        wordpress_options.each do |task|
          yield task if options[task] || (options["all"] && options[task] != false)
        end
      end

      def wordpress_options
        %w[wordpress uploads themes plugins mu_plugins languages db]
      end

      def ensure_wordpress_options_presence!(options)
        return if (options.keys & (wordpress_options + ["all"])).present?

        puts "No options given. See wordmove --help"
        exit 1
      end

      def logger
        Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
      end
    end

    desc "list", "List all environments and vhosts"
    shared_options.each do |option, args|
      method_option option, args
    end
    def list
      Wordmove::EnvironmentsList.print(options)
    rescue Wordmove::MovefileNotFound => e
      logger.error(e.message)
      exit 1
    rescue Psych::SyntaxError => e
      logger.error("Your movefile is not parsable due to a syntax error: #{e.message}")
      exit 1
    end

    desc "pull", "Pulls WP data from remote host to the local machine"
    shared_options.each do |option, args|
      method_option option, args
    end
    def pull
      ensure_wordpress_options_presence!(options)
      begin
        deployer = Wordmove::Deployer::Base.deployer_for(options.deep_symbolize_keys)
      rescue MovefileNotFound => e
        logger.error(e.message)
        exit 1
      end

      Wordmove::Hook.run(:pull, :before, options)

      guardian = Wordmove::Guardian.new(options: options, action: :pull)

      handle_options(options) do |task|
        deployer.send("pull_#{task}") if guardian.allows(task.to_sym)
      end

      Wordmove::Hook.run(:pull, :after, options)
    end

    desc "push", "Pushes WP data from local machine to remote host"
    shared_options.each do |option, args|
      method_option option, args
    end
    def push
      ensure_wordpress_options_presence!(options)
      begin
        deployer = Wordmove::Deployer::Base.deployer_for(options.deep_symbolize_keys)
      rescue MovefileNotFound => e
        logger.error(e.message)
        exit 1
      end

      Wordmove::Hook.run(:push, :before, options)

      guardian = Wordmove::Guardian.new(options: options, action: :push)

      handle_options(options) do |task|
        deployer.send("push_#{task}") if guardian.allows(task.to_sym)
      end

      Wordmove::Hook.run(:push, :after, options)
    end
  end
end
