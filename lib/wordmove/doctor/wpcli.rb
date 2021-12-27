module Wordmove
  class Doctor
    class Wpcli
      attr_reader :logger

      def initialize
        @logger = Logger.new($stdout).tap { |l| l.level = Logger::INFO }
      end

      def check!
        logger.task 'Checking local wp-cli installation'

        if in_path?
          logger.success 'wp-cli is correctly installed'

          if up_to_date?
            logger.success 'wp-cli is up to date'
          else
            logger.error <<-LONG
  wp-cli is not up to date.
                Use `wp cli update` to update to the latest version.
            LONG
          end
        else
          logger.error <<-LONG
  wp-cli is not installed (or not in your $PATH).
              Read http://wp-cli.org/#installing for installation info.
          LONG
        end
      end

      private

      def in_path?
        system('which wp', out: File::NULL)
      end

      def up_to_date?
        `wp cli check-update --format=json --allow-root`.empty?
      end
    end
  end
end
