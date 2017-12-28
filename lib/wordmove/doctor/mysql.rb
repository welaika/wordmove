module Wordmove
  class Doctor
    class Mysql
      attr_reader :config, :logger

      def initialize(movefile_name = nil, movefile_dir = '.')
        @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
        begin
          @config = Wordmove::Movefile.new(movefile_name, movefile_dir).fetch[:local][:database]
        rescue Psych::SyntaxError
          return
        end
      end

      def check!
        logger.task "Checking local database commands and connection"

        return logger.error "Can't connect to mysql using your movefile.yml" if config.nil?

        mysql_client_doctor
        mysqldump_doctor
        mysql_server_doctor
      end

      private

      def mysql_client_doctor
        if system("which mysql", out: File::NULL)
          logger.success "`mysql` command is in $PATH"
        else
          logger.error "`mysql` command is not in $PATH"
        end
      end

      def mysqldump_doctor
        if system("which mysqldump", out: File::NULL)
          logger.success "`mysqldump` command is in $PATH"
        else
          logger.error "`mysqldump` command is not in $PATH"
        end
      end

      def mysql_server_doctor
        command = ["mysql"]
        command << "-u #{config['user']}"
        command << "-p#{config['password']}" unless config['password'].blank?
        command << "-h #{config['host']}"
        command << "-e'QUIT'"
        command = command.join(" ")

        if system(command, out: File::NULL, err: File::NULL)
          logger.success "Successfully connected to the database"
        else
          logger.error <<~LONG
            We can't connect to the database using credentials
            specified in the Movefile. Double check them or try
            to debug your system configuration.

            The command used to test was:

            #{command}
          LONG
        end
      end
    end
  end
end
