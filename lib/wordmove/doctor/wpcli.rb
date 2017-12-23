module Wordmove
  class Doctor
    class Wpcli
      attr_reader :logger

      def initialize
        @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
      end

      def check!
        logger.task "Checking local wp-cli installation"

        if in_path? && up_to_date?
          logger.success "wp-cli is correctly installed and up to date"
        else
          logger.error "wp-cli is not installed (or not in your $PATH) or not up to date"
        end
      end

      private

      def in_path?
        system('which wp')
      end

      def up_to_date?
        `wp cli check-update --format=json`.empty?
      end
    end
  end
end
