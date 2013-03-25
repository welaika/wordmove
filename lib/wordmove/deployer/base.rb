require 'active_support/core_ext'
require 'wordmove/logger'
require 'wordmove/wordpress_directory'
require 'wordmove/sql_mover'
require 'escape'

module Wordmove
  module Deployer

    class Base
      attr_reader :options
      attr_reader :logger
      attr_reader :environment

      def self.deployer_for(cli_options)
        options = fetch_movefile(cli_options[:config])
        available_enviroments = options.keys.map(&:to_sym) - [ :local ]
        options.merge!(cli_options)
        recursive_symbolize_keys!(options)

        if available_enviroments.size > 1 && options[:environment].nil?
          raise "You need to specify an environment with --environment parameter"
        end

        environment = (options[:environment] || available_enviroments.first).to_sym

        if options[environment][:ftp]
          require 'wordmove/deployer/ftp'
          FTP.new(environment, options)
        elsif options[environment][:ssh]
          require 'wordmove/deployer/ssh'
          SSH.new(environment, options)
        else
          raise Thor::Error, "No valid adapter found."
        end
      end

      def self.fetch_movefile(path)
        path ||= "Movefile"
        unless File.exists?(path)
          raise Thor::Error, "Could not find a valid Movefile"
        end
        YAML::load(File.open(path))
      end

      def initialize(environment, options = {})
        @environment = environment.to_sym
        @options = options
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
      end

      def push_db;
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

      def get_options_for_wordpress(type)
        {
          :local_path    => local_options[:wordpress_path],
          :remote_path   => remote_options[:wordpress_path],
          :exclude_paths => paths_to_exclude.push(send("#{type}_wp_content_dir").relative_path)
        }
      end

      def push_wordpress
        logger.task "Pushing wordpress core"
        options = get_options_for_wordpress("local")
        remote_put_directory(options[:local_path], options[:remote_path], options[:exclude_paths])
      end

      def pull_wordpress
        logger.task "Pulling wordpress core"
        options = get_options_for_wordpress("remote")
        remote_get_directory(options[:remote_path], options[:local_path], options[:exclude_paths])
      end

      protected

      def paths_to_exclude
        remote_options[:exclude] || Array.new
      end

      def run(command)
        logger.task_step true, command
        unless simulate?
          system(command)
          raise "Return code reports an error" unless $?.success?
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
            SqlMover.new(save_to_path, local, remote).move!
          end
        end
      end

      def mysql_dump_command(options, save_to_path)
        arguments = [ "mysqldump" ]
        arguments << "--host=#{options[:host]}" if options[:host].present?
        arguments << "--user=#{options[:user]}" if options[:user].present?
        arguments << "--password=#{options[:password]}" if options[:password].present?
        arguments << "--default-character-set=#{options[:charset]}" if options[:charset].present?
        arguments << options[:name]
        Escape.shell_command(arguments) + " > #{save_to_path}"
      end

      def mysql_import_command(dump_path, options)
        arguments = [ "mysql" ]
        arguments << "--host=#{options[:host]}" if options[:host].present?
        arguments << "--user=#{options[:user]}" if options[:user].present?
        arguments << "--password=#{options[:password]}" if options[:password].present?
        arguments << "--database=#{options[:name]}"
        Escape.shell_command(arguments) + " < #{dump_path}"
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

      private

      def self.recursive_symbolize_keys! hash
        hash.symbolize_keys!
        hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
      end

    end

  end
end
