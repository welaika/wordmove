module Wordmove
  class List
    class << self
      def start(cli_options)
        new(cli_options).start
      end
    end

    def initialize(options)
      @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
      @movefile = Wordmove::Movefile.new(options[:config])
      @remote_vhosts = []
      @local_vhost = []
    end

    def start
      contents = parse_movefile(movefile: movefile)
      generate_vhost_list(contents: contents)
      output
    end

    def output_string(vhost_list:)
      return 'vhost list is empty' if vhost_list.empty?

      ''.tap do |retval|
        vhost_list.each do |entry|
          retval << "#{entry[:env]}: #{entry[:vhost]}\n"
        end
      end
    end

    #
    # return env, vhost map
    # Exp. {:env=>:local, :vhost=>"http://vhost.local"},
    #      {:env=>:production, :vhost=>"http://example.com"}
    #
    def generate_vhost_list(contents:)
      # select object which has 'vhost' only
      vhosts = select_vhost(contents: contents)
      vhosts.each do |list|
        if list[:env] == :local
          @local_vhost << list
        else
          @remote_vhosts << list
        end
      end
    end

    private

    attr_reader :movefile, :logger, :remote_vhosts, :local_vhost

    def select_vhost(contents:)
      target = contents.select { |_key, env| env[:vhost].present? }
      target.map { |key, env| { env: key, vhost: env[:vhost] } }
    end

    def parse_movefile(movefile:)
      movefile.fetch
    end

    def output
      logger.task('Listing Local')
      puts output_string(vhost_list: local_vhost)

      logger.task('Listing Remotes')
      puts output_string(vhost_list: remote_vhosts)
    end
  end
end
