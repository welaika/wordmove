require 'active_support/core_ext'
require 'wordmove/logger'
require 'escape'

module Wordmove
  module Deployer

    class Base
      attr_reader :options
      attr_reader :logger

      def self.deployer_for(options)
        options = fetch_movefile(options[:config]).merge(options)
        recursive_symbolize_keys!(options)
        if options[:remote][:ftp]
          require 'wordmove/deployer/ftp'
          FTP.new(options)
        elsif options[:remote][:ssh]
          require 'wordmove/deployer/ssh'
          SSH.new(options)
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

      def initialize(options = {})
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

      %w(uploads themes plugins).each do |task|
        define_method "push_#{task}" do
          logger.task "Pushing #{task.titleize}"
          remote_put_directory(local_wpcontent_path(task), remote_wpcontent_path(task))
        end

        define_method "pull_#{task}" do
          logger.task "Pulling #{task.titleize}"
          remote_get_directory(remote_wpcontent_path(task), local_wpcontent_path(task))
        end
      end

      protected

      def run(command)
        logger.task_step true, command
        unless simulate?
          system(command)
        end
      end

      def simulate?
        options[:simulate]
      end

      def local_wpcontent_path(*args)
        File.join(options[:local][:wordpress_path], "wp-content", *args)
      end

      def remote_wpcontent_path(*args)
        File.join(options[:remote][:wordpress_path], "wp-content", *args)
      end

      def adapt_sql(save_to_path, local, remote)
        logger.task_step true, "adapt dump"
        unless simulate?
          File.open(save_to_path, 'a') do |file|
            file.write "UPDATE wp_options SET option_value=\"#{remote[:vhost]}\" WHERE option_name=\"siteurl\" OR option_name=\"home\";\n"
          end
        end
      end

      def mysql_dump_command(options, save_to_path)
        arguments = [ "mysqldump" ]
        arguments << "--host=#{options[:host]}" if options[:host].present?
        arguments << "--user=#{options[:user]}" if options[:user].present?
        arguments << "--password=#{options[:password]}" if options[:password].present?
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

      private

      def self.recursive_symbolize_keys! hash
        hash.symbolize_keys!
        hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
      end

    end

  end
end
