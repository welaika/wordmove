module Wordmove
  class Movefile
    attr_reader :logger

    def initialize
      @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
    end

    def fetch(name = nil, start_dir = current_dir)
      entries = if name.nil?
                  Dir["#{File.join(start_dir, '{M,m}ovefile')}{,.yml,.yaml}"]
                else
                  Dir["#{File.join(start_dir, name)}{,.yml,.yaml}"]
                end

      if entries.empty?
        raise MovefileNotFound, "Could not find a valid Movefile" if last_dir?(start_dir)
        return fetch(name, upper_dir(start_dir))
      end

      found = entries.first
      logger.task("Using Movefile: #{found}")
      YAML.safe_load(ERB.new(File.read(found)).result, [], [], true)
    end

    private

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
