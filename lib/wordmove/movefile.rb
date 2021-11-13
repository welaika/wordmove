module Wordmove
  class Movefile
    attr_reader :logger,
                :config_file_name,
                :start_dir,
                :options,
                :cli_options

    def initialize(cli_options = {}, start_dir = nil, verbose = true) # rubocop:disable Style/OptionalBooleanParameter
      @logger = Logger.new($stdout).tap { |l| l.level = Logger::DEBUG }
      @cli_options = cli_options.deep_symbolize_keys || {}
      @config_file_name = @cli_options.fetch(:config, nil)
      @start_dir = start_dir || current_dir

      @options = fetch(verbose)
                 .deep_symbolize_keys!
                 .freeze
    end

    def environment
      available_enviroments = extract_available_envs(options)

      if available_enviroments.size > 1 && cli_options[:environment].nil?
        raise(
          UndefinedEnvironment,
          'You need to specify an environment with --environment parameter'
        )
      end

      if cli_options[:environment].present? &&
         !available_enviroments.include?(cli_options[:environment].to_sym)
        raise UndefinedEnvironment, "No environment found for \"#{options[:environment]}\". "\
                                    "Available Environments: #{available_enviroments.join(' ')}"
      end

      # NOTE: This is Hash#fetch, not self.fetch.
      cli_options.fetch(:environment, available_enviroments.first).to_sym
    end

    def secrets
      secrets = []
      options.each_key do |env|
        secrets << options.dig(env, :database, :password)
        secrets << options.dig(env, :database, :host)
        secrets << options.dig(env, :vhost)
        secrets << options.dig(env, :ssh, :password)
        secrets << options.dig(env, :ssh, :host)
        secrets << options.dig(env, :ftp, :password)
        secrets << options.dig(env, :ftp, :host)
        secrets << options.dig(env, :wordpress_path)
      end

      secrets.compact.delete_if(&:empty?)
    end

    private

    def fetch(verbose = true) # rubocop:disable Style/OptionalBooleanParameter
      load_dotenv

      entries = if config_file_name.nil?
                  Dir["#{File.join(start_dir, '{M,m}ovefile')}{,.yml,.yaml}"]
                else
                  Dir["#{File.join(start_dir, config_file_name)}{,.yml,.yaml}"]
                end

      if entries.empty?
        if last_dir?(start_dir)
          raise MovefileNotFound, 'Could not find a valid Movefile. Searched'\
                                  " for filename \"#{config_file_name}\" in folder \"#{start_dir}\""
        end

        @start_dir = upper_dir(start_dir)
        return fetch(verbose)
      end

      found = entries.first
      logger.task("Using Movefile: #{found}") if verbose == true
      YAML.safe_load(ERB.new(File.read(found)).result, [], [], true).deep_symbolize_keys!
    end

    def load_dotenv
      env_files = Dir[File.join(start_dir, '.env')]

      found_env = env_files.first

      return false unless found_env.present?

      logger.info("Using .env file: #{found_env}")
      Dotenv.load(found_env)
    end

    def extract_available_envs(options)
      options.keys - %i[local global]
    end

    def last_dir?(directory)
      directory == '/' || File.exist?(File.join(directory, 'wp-config.php'))
    end

    def upper_dir(directory)
      File.expand_path(File.join(directory, '..'))
    end

    def current_dir
      '.'
    end
  end
end
