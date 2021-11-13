module Wordmove
  class CLI < Thor
    map %w[--version -v] => :__print_version

    desc '--version, -v', 'Print the version'
    def __print_version
      puts Wordmove::VERSION
    end

    desc 'init', 'Generates a brand new movefile.yml'
    def init
      Wordmove::Generators::Movefile.start
    end

    desc 'doctor', 'Do some local configuration and environment checks'
    def doctor
      Wordmove::Doctor.start
    end

    shared_options = {
      wordpress: { aliases: '-w', type: :boolean },
      uploads: { aliases: '-u', type: :boolean },
      themes: { aliases: '-t', type: :boolean },
      plugins: { aliases: '-p', type: :boolean },
      mu_plugins: { aliases: '-m', type: :boolean },
      languages: { aliases: '-l', type: :boolean },
      db: { aliases: '-d', type: :boolean },
      verbose: { aliases: '-v', type: :boolean },
      simulate: { aliases: '-s', type: :boolean },
      environment: { aliases: '-e' },
      config: { aliases: '-c' },
      debug: { type: :boolean },
      no_adapt: { type: :boolean },
      all: { type: :boolean }
    }

    no_tasks do
      def self.wordpress_options
        %i[wordpress uploads themes plugins mu_plugins languages db]
      end

      def ensure_wordpress_options_presence!(options)
        return if (
          options.deep_symbolize_keys.keys & (self.class.wordpress_options + [:all])
        ).present?

        puts 'No options given. See wordmove --help'
        exit 1
      end

      def initial_context
        cli_options = options.deep_symbolize_keys
        movefile = Wordmove::Movefile.new(cli_options)

        [cli_options, movefile]
      end

      def logger
        Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
      end
    end

    desc 'list', 'List all environments and vhosts'
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

    desc 'pull', 'Pulls WP data from remote host to the local machine'
    shared_options.each do |option, args|
      method_option option, args
    end
    def pull
      ensure_wordpress_options_presence!(options)

      begin
        cli_options, movefile = initial_context

        result = if movefile.options[movefile.environment][:ssh]
                   Wordmove::Actions::Ssh::Pull.call(cli_options: cli_options, movefile: movefile)
                 elsif movefile.options[movefile.environment][:ftp]
                   raise FtpNotSupportedException
                 else
                   raise NoAdapterFound, 'No valid adapter found.'
                 end

        result.success? ? exit(0) : exit(1)
      rescue MovefileNotFound => e
        logger.error(e.message)
        exit 1
      rescue NoAdapterFound => e
        logger.error(e.message)
        exit 1
      rescue FtpNotSupportedException => e
        logger.error(e.message)
        exit 1
      end
    end

    desc 'push', 'Pushes WP data from local machine to remote host'
    shared_options.each do |option, args|
      method_option option, args
    end
    def push
      ensure_wordpress_options_presence!(options)

      begin
        cli_options, movefile = initial_context

        result = if movefile.options[movefile.environment][:ssh]
                   Wordmove::Actions::Ssh::Push.call(cli_options: cli_options, movefile: movefile)
                 elsif movefile.options[movefile.environment][:ftp]
                   raise FtpNotSupportedException
                 else
                   raise NoAdapterFound, 'No valid adapter found.'
                 end

        result.success? ? exit(0) : exit(1)
      rescue MovefileNotFound => e
        logger.error(e.message)
        exit 1
      rescue NoAdapterFound => e
        logger.error(e.message)
        exit 1
      rescue FtpNotSupportedException => e
        logger.error(e.message)
        exit 1
      end
    end
  end
end
