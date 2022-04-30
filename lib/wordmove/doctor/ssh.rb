module Wordmove
  class Doctor
    class Ssh
      attr_reader :logger

      def initialize
        @logger = Logger.new($stdout).tap { |l| l.level = Logger::INFO }
      end

      def check!
        logger.task 'Checking SSH client'

        if system('which ssh', out: File::NULL, err: File::NULL)
          logger.success 'SSH command found'
        else
          logger.error "SSH command not found. And belive me: it's really strange it's not there."
        end
      end
    end
  end
end
