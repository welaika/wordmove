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
        if last_dir?(start_dir)
          raise MovefileNotFound, "Could not find a valid Movefile. Searched"\
                                  " for filename \"#{name}\" in folder \"#{start_dir}\""
        end

        @start_dir = upper_dir(start_dir)
        return fetch(verbose)
      end

      found = entries.first
      logger.task("Using Movefile: #{found}") if verbose == true
      YAML.safe_load(ERB.new(File.read(found)).result).deep_symbolize_keys!
    end

    def load_dotenv(cli_options = {})
      env = environment(cli_options)
      env_files = Dir[File.join(start_dir, ".env{.#{env},}")]

      found_env = env_files.first

      return false unless found_env.present?

      logger.info("Using .env file: #{found_env}")
      Dotenv.load(found_env)
    end

    def environment(cli_options = {})
      options = fetch(false)
      available_enviroments = extract_available_envs(options)
      options.merge!(cli_options).deep_symbolize_keys!

      if options[:environment] != 'local'
        if available_enviroments.size > 1 && options[:environment].nil?
          raise(
            UndefinedEnvironment,
            "You need to specify an environment with --environment parameter"
          )
        end

        if options[:environment].present?
          unless available_enviroments.include?(options[:environment].to_sym)
            raise UndefinedEnvironment, "No environment found for \"#{options[:environment]}\". "\
                                        "Available Environments: #{available_enviroments.join(' ')}"
          end
        end
      end

      (options[:environment] || available_enviroments.first).to_sym
    end

    def secrets
      options = fetch(false)

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
