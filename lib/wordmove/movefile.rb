module Wordmove
  class Movefile
    attr_reader :logger, :name, :start_dir

    def initialize(name = nil, start_dir = current_dir)
      @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
      @name = name
      @start_dir = start_dir
    end

    def fetch(verbose = true)
      entries = if name.nil?
                  Dir["#{File.join(start_dir, '{M,m}ovefile')}{,.yml,.yaml}"]
                else
                  Dir["#{File.join(start_dir, name)}{,.yml,.yaml}"]
                end

      if entries.empty?
        raise MovefileNotFound, "Could not find a valid Movefile" if last_dir?(start_dir)
        @start_dir = upper_dir(start_dir)
        return fetch
      end

      found = entries.first
      logger.task("Using Movefile: #{found}") if verbose == true
      YAML.safe_load(ERB.new(File.read(found)).result, [], [], true).deep_symbolize_keys!
    end

    def dotenv(cli_options = {})
      env = cli_options['environment'] || cli_options[:environment]
      env_files = Dir[File.join(start_dir, ".env{.#{env},}")]

      found_env = env_files.first
      logger.task("Using .env file: #{found_env}") if found_env && found_env != ENV['dotenv']
      ENV['dotenv'] = found_env

      Dotenv.load(found_env) if found_env
    end

    def environment(cli_options = {})
      options = fetch(false)
      available_enviroments = extract_available_envs(options)
      options.merge!(cli_options).deep_symbolize_keys!

      if available_enviroments.size > 1 && options[:environment].nil?
        raise(
          UndefinedEnvironment,
          "You need to specify an environment with --environment parameter"
        )
      end

      (options[:environment] || available_enviroments.first).to_sym
    end

    private

    def extract_available_envs(options)
      options.keys.map(&:to_sym) - %i[local global]
    end

    def last_dir?(directory)
      directory == "/" || File.exist?(File.join(directory, 'wp-config.php'))
    end

    def upper_dir(directory)
      File.expand_path(File.join(directory, '..'))
    end

    def current_dir
      '.'
    end
  end
end
