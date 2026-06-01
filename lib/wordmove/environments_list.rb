module Wordmove
  class EnvironmentsList
    attr_reader :movefile, :logger, :remote_vhosts, :local_vhost

    class << self
      def print(cli_options)
        new(cli_options).print
      end
    end

    def initialize(options)
      @logger = Logger.new($stdout).tap { |l| l.level = Logger::INFO }
      @movefile = Wordmove::Movefile.new(options)
      @remote_vhosts = []
      @local_vhost = []
    end

    def print
      contents = parse_movefile(movefile:)
      generate_vhost_list(contents:)
      output
    end

    private

    def select_vhost(contents:)
      target = contents.select { |_key, env| env[:vhost].present? }
      target.map { |key, env| { env: key, vhost: env[:vhost] } }
    end

    def parse_movefile(movefile:)
      movefile.options
    end

    def output
      logger.task('Listing Local')
      logger.plain(output_string(vhost_list: local_vhost))

      logger.task('Listing Remotes')
      logger.plain(output_string(vhost_list: remote_vhosts))
    end

    def output_string(vhost_list:)
      return 'vhost list is empty' if vhost_list.empty?

      vhost_list.each_with_object('') do |entry, retval|
        retval << "#{entry[:env]}: #{entry[:vhost]}\n"
      end
    end

    #
    # return env, vhost map
    # Exp. {:env=>:local, :vhost=>"http://vhost.local"},
    #      {:env=>:production, :vhost=>"http://example.com"}
    #
    def generate_vhost_list(contents:)
      # select object which has 'vhost' only
      vhosts = select_vhost(contents:)
      vhosts.each do |list|
        if list[:env] == :local
          @local_vhost << list
        else
          @remote_vhosts << list
        end
      end
    end
  end
end
