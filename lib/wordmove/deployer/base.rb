module Wordmove
  module Deployer
    class Base
      attr_reader :options
      attr_reader :logger
      attr_reader :environment

      class << self
        def deployer_for(cli_options)
          options = fetch_movefile(cli_options[:config])
          available_enviroments = extract_available_envs(options)
          options.merge!(cli_options).deep_symbolize_keys!

          if available_enviroments.size > 1 && options[:environment].nil?
            raise UndefinedEnvironment, "You need to specify an environment with --environment parameter"
          end
          environment = (options[:environment] || available_enviroments.first).to_sym

          if options[environment][:ftp]
            FTP.new(environment, options)
          elsif options[environment][:ssh]
            SSH.new(environment, options)
          else
            raise NoAdapterFound, "No valid adapter found."
          end
        end

        def extract_available_envs(options)
          options.keys.map(&:to_sym) - [ :local ]
        end

        def fetch_movefile(name = nil, start_dir = current_dir)
          name ||= "Movefile"
          entries = Dir["#{File.join(start_dir, name)}*"]

          if entries.empty?
            if last_dir?(start_dir)
              raise MovefileNotFound, "Could not find a valid Movefile"
            else
              return fetch_movefile(name, upper_dir(start_dir))
            end
          end

          found = entries.first
          logger.task("Using Movefile: #{found}")
          YAML::load(File.open(found))
        end

        def current_dir
          '.'
        end

        def last_dir?(directory)
          directory == "/" || File.exists?(File.join(directory, 'wp-config.php'))
        end

        def upper_dir(directory)
          File.expand_path(File.join(directory, '..'))
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

      %w(uploads themes plugins languages).each do |task|
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
        remote_options[:exclude] || Array.new
      end

      def run(command)
        logger.task_step true, command
        unless simulate?
          system(command)
          raise ShellCommandError, "Return code reports an error" unless $?.success?
        end
      end

      def download(url, local_path)
        logger.task_step true, "download #{url} > #{local_path}"
        unless simulate?
          open(local_path, 'w') do |file|
            file << open(url).read
          end
        end
      end

      def simulate?
        options[:simulate]
      end

      [ WordpressDirectory::PATH::WP_CONTENT,
        WordpressDirectory::PATH::PLUGINS,
        WordpressDirectory::PATH::THEMES,
        WordpressDirectory::PATH::UPLOADS,
        WordpressDirectory::PATH::LANGUAGES
      ].each do |type|
        [ :remote, :local ].each do |location|
          define_method "#{location}_#{type}_dir" do
            options = send("#{location}_options")
            WordpressDirectory.new(type, options)
          end
        end
      end

      def adapt_sql(save_to_path, local, remote)
        unless options[:no_adapt]
          logger.task_step true, "adapt dump"
          unless simulate?
            SqlAdapter.new(save_to_path, local, remote).adapt!
          end
        end
      end

      def mysql_dump_command(options, save_to_path, tables)
        command = mysql_common_auth_for_command('mysqldump', options)
        command << Shellwords.escape(options[:name])
        command << sanitize_fetched_tables(tables)
        command << "--result-file=#{Shellwords.escape(save_to_path)}"
        command.join(" ")
      end

      def mysql_import_command(dump_path, options)
        command = mysql_common_auth_for_command('mysql', options)
        command << "--database=#{Shellwords.escape(options[:name])}"
        command << "--execute=#{Shellwords.escape("SOURCE #{dump_path}")}"
        command.join(" ")
      end

      def fetch_tables(options)
        command = mysql_common_auth_for_command('mysql', options)
        command << "--batch"
        command << "--execute=#{Shellwords.escape("SHOW TABLES FROM #{options[:name]} LIKE \"#{options[:prefix]}%\";")}"
        command = command.join(" ")
      end

      def sanitize_fetched_tables(stdout)
        stdout.split.drop(2).join(" ")
      end

      def mysql_common_auth_for_command(command, options)
        command = [command]
        command << "--host=#{Shellwords.escape(options[:host])}" if options[:host].present?
        command << "--port=#{Shellwords.escape(options[:port])}" if options[:port].present?
        command << "--user=#{Shellwords.escape(options[:user])}" if options[:user].present?
        command << "--password=#{Shellwords.escape(options[:password])}" if options[:password].present?
        command << "--default-character-set=#{Shellwords.escape(options[:charset])}" if options[:charset].present?

        command
      end

      def rm_command(path)
        "rm #{Shellwords.escape(path)}"
      end

      def save_local_db(local_dump_path)
        # dump local mysql into file
        tables = %x(#{fetch_tables(local_options[:database])})
        run mysql_dump_command(local_options[:database], local_dump_path, tables)
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
