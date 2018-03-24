module Wordmove
  module Deployer
    class Base
      attr_reader :options
      attr_reader :logger
      attr_reader :environment

      class << self
        def deployer_for(cli_options)
          movefile = Wordmove::Movefile.new(cli_options[:config])
          options = movefile.fetch.merge! cli_options
          environment = movefile.environment(cli_options)

          return FTP.new(environment, options) if options[environment][:ftp]

          if options[environment][:ssh] && options[:global][:sql_adapter] == 'wpcli'
            return Ssh::WpcliSqlAdapter.new(environment, options)
          end

          if options[environment][:ssh] && options[:global][:sql_adapter] == 'default'
            return Ssh::DefaultSqlAdapter.new(environment, options)
          end

          raise NoAdapterFound, "No valid adapter found."
        end

        def current_dir
          '.'
        end

        def logger
          Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
        end
      end

      def initialize(environment, options = {})
        @environment = environment.to_sym
        @options = options
        @logger = self.class.logger
      end

      def push_db
        logger.task "Pushing Database"
      end

      def pull_db
        logger.task "Pulling Database"
      end

      def remote_get_directory(directory); end

      def remote_put_directory(directory); end

      %w[uploads themes plugins mu_plugins languages].each do |task|
        define_method "push_#{task}" do
          logger.task "Pushing #{task.titleize}"
          local_path = send("local_#{task}_dir").path
          remote_path = send("remote_#{task}_dir").path
          remote_put_directory(local_path, remote_path, paths_to_exclude)
        end

        define_method "pull_#{task}" do
          logger.task "Pulling #{task.titleize}"
          local_path = send("local_#{task}_dir").path
          remote_path = send("remote_#{task}_dir").path
          remote_get_directory(remote_path, local_path, paths_to_exclude)
        end
      end

      def exclude_dir_contents(path)
        "#{path}/*"
      end

      def push_wordpress
        logger.task "Pushing wordpress core"

        local_path = local_options[:wordpress_path]
        remote_path = remote_options[:wordpress_path]
        exclude_wp_content = exclude_dir_contents(local_wp_content_dir.relative_path)
        exclude_paths = paths_to_exclude.push(exclude_wp_content)

        remote_put_directory(local_path, remote_path, exclude_paths)
      end

      def pull_wordpress
        logger.task "Pulling wordpress core"

        local_path = local_options[:wordpress_path]
        remote_path = remote_options[:wordpress_path]
        exclude_wp_content = exclude_dir_contents(remote_wp_content_dir.relative_path)
        exclude_paths = paths_to_exclude.push(exclude_wp_content)

        remote_get_directory(remote_path, local_path, exclude_paths)
      end

      protected

      def paths_to_exclude
        remote_options[:exclude] || []
      end

      def run(command)
        logger.task_step true, command
        return true if simulate?

        system(command)
        raise ShellCommandError, "Return code reports an error" unless $CHILD_STATUS.success?
      end

      def download(url, local_path)
        logger.task_step true, "download #{url} > #{local_path}"

        return true if simulate?

        open(local_path, 'w') do |file|
          file << open(url).read
        end
      end

      def simulate?
        options[:simulate]
      end

      [
        WordpressDirectory::Path::WP_CONTENT,
        WordpressDirectory::Path::PLUGINS,
        WordpressDirectory::Path::MU_PLUGINS,
        WordpressDirectory::Path::THEMES,
        WordpressDirectory::Path::UPLOADS,
        WordpressDirectory::Path::LANGUAGES
      ].each do |type|
        %i[remote local].each do |location|
          define_method "#{location}_#{type}_dir" do
            options = send("#{location}_options")
            WordpressDirectory.new(type, options)
          end
        end
      end

      def mysql_dump_command(options, save_to_path)
        command = ["mysqldump"]
        command << "--host=#{Shellwords.escape(options[:host])}" if options[:host].present?
        command << "--port=#{Shellwords.escape(options[:port])}" if options[:port].present?
        command << "--user=#{Shellwords.escape(options[:user])}" if options[:user].present?
        if options[:protocol].present?
          command << "--protocol=#{Shellwords.escape(options[:protocol])}"
        end
        if options[:password].present?
          command << "--password=#{Shellwords.escape(options[:password])}"
        end
        if options[:charset].present?
          command << "--default-character-set=#{Shellwords.escape(options[:charset])}"
        end
        command << "--result-file=\"#{save_to_path}\""
        if options[:mysqldump_options].present?
          command << Shellwords.split(options[:mysqldump_options])
        end
        command << Shellwords.escape(options[:name])
        command.join(" ")
      end

      def mysql_import_command(dump_path, options)
        command = ["mysql"]
        command << "--host=#{Shellwords.escape(options[:host])}" if options[:host].present?
        command << "--port=#{Shellwords.escape(options[:port])}" if options[:port].present?
        command << "--user=#{Shellwords.escape(options[:user])}" if options[:user].present?
        if options[:protocol].present?
          command << "--protocol=#{Shellwords.escape(options[:protocol])}"
        end
        if options[:password].present?
          command << "--password=#{Shellwords.escape(options[:password])}"
        end
        if options[:charset].present?
          command << "--default-character-set=#{Shellwords.escape(options[:charset])}"
        end
        command << "--database=#{Shellwords.escape(options[:name])}"
        command << "--execute=\"SET autocommit=0;SOURCE #{dump_path};COMMIT\""
        command.join(" ")
      end

      def compress_command(path)
        command = ["gzip"]
        command << "--best"
        command << "--force"
        command << "\"#{path}\""
        puts command.join(" ")
        command.join(" ")
      end

      def uncompress_command(path)
        command = ["gzip"]
        command << "-d"
        command << "--force"
        command << "\"#{path}\""
        puts command.join(" ")
        command.join(" ")
      end

      def local_delete(path)
        logger.task_step true, "delete: '#{path}'"
        File.delete(path) unless simulate?
      end

      def save_local_db(local_dump_path)
        # dump local mysql into file
        run mysql_dump_command(local_options[:database], local_dump_path)
      end

      def remote_options
        options[environment].clone
      end

      def local_options
        options[:local].clone
      end
    end
  end
end
