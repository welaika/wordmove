module Wordmove
  class Doctor
    class Rsync
      attr_reader :logger

      def initialize
        @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
      end

      def check!
        logger.task "Checking rsync"

        version_output = `rsync --version | head -n1 2>&1`

        if version_output.downcase.include?('openrsync')
          protocol_version = version_output[/protocol version (\d+)/i, 1]
          logger.success "openrsync detected (protocol version #{protocol_version || 'unknown'})"
        elsif (match = /\d+\.\d+\.\d+/.match(version_output))
          logger.success "rsync is installed at version #{match[0]}"
        else
          logger.error "rsync not found or the version could not be detected. "\
                       "Output was: #{version_output.strip}"
        end
      end
    end
  end
end
