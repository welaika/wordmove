module Wordmove
  class Doctor
    class Rsync
      attr_reader :logger

      def initialize
        @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
      end

      def check!
        logger.task "Checking rsync"

        if (version = /\d\.\d.\d/.match(`rsync --version | head -n1`)[0])
          logger.success "rsync is installed at version #{version}"
        else
          logger.error "rsync not found. And belive me: it's really strange it's not there."
        end
      end
    end
  end
end
