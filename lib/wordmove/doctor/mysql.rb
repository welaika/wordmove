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
        mysql_database_doctor
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
        command = mysql_command

        if system(command, out: File::NULL, err: File::NULL)
          logger.success "Successfully connected to the MySQL server"
        else
          logger.error <<-LONG
  We can't connect to the MySQL server using credentials
                specified in the Movefile. Double check them or try
                to debug your system configuration.

                The command used to test was:

                #{command}
          LONG
        end
      end

      def mysql_database_doctor
        command = mysql_command(database: config[:name])

        if system(command, out: File::NULL, err: File::NULL)
          logger.success "Successfully connected to the database"
        else
          logger.error <<-LONG
  We can't connect to the database using credentials
                specified in the Movefile, or the database does not
                exists. Double check them or try to debug your
                system configuration.

                The command used to test was:

                #{command}
          LONG
        end
      end

      def mysql_command(database: nil)
        command = ["mysql"]
        command << "--host=#{Shellwords.escape(config[:host])}" if config[:host].present?
        command << "--port=#{Shellwords.escape(config[:port])}" if config[:port].present?
        command << "--socket=\"#{config[:socket]}\"" if config[:socket].present?
        command << "--user=#{Shellwords.escape(config[:user])}" if config[:user].present?
        if config[:password].present?
          command << "--password=#{Shellwords.escape(config[:password])}"
        end
        command << database if database.present?
        command << "-e'QUIT'"
        command.join(" ")
      end
    end
  end
end
