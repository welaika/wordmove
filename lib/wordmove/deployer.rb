require 'active_support/core_ext'
require 'hashie'
require 'wordmove/hosts/local_host'
require 'wordmove/hosts/remote_host'
require 'wordmove/logger'
require 'wordmove/sql_mover'

module Wordmove

  class Deployer

    attr_reader :options
    attr_reader :logger

    def initialize(options = {})
      @options = Hashie::Mash.new(options)
      @logger = Logger.new
      @logger.level = options.verbose ? Logger::VERBOSE : Logger::INFO
    end

    def push
      informative_errors do
        unless options.skip_db
          logger.info "Pushing the DB..."
          push_db
        end

        remotely do |host|
          %w(uploads themes plugins).each do |step|
            unless options.send("skip_#{step}")
              logger.info "Pushing wp-content/#{step}..."
              host.download_dir local_wpcontent_path(step), remote_wpcontent_path(step)
            end
          end
        end
      end
    end

    def pull
      informative_errors do
        unless options.skip_db
          logger.info "Pulling the DB..."
          pull_db
        end

        remotely do |host|
          %w(uploads themes plugins).each do |step|
            unless options.send("skip_#{step}")
              logger.info "Pulling wp-content/#{step}..."
              host.upload_dir remote_wpcontent_path(step), local_wpcontent_path(step)
            end
          end
        end
      end
    end

    private

    def push_db
      local_mysql_dump_path = local_wpcontent_path("database_dump.sql")
      remote_mysql_dump_path = remote_wpcontent_path("database_dump.sql")

      locally do |host|
        host.run "mysqldump", "--host=#{config.local.database.host}", "--user=#{config.local.database.username}", "--password=#{config.local.database.password}", config.local.database.name, :stdout => local_mysql_dump_path
        if options.adapt_sql
          Wordmove::SqlMover.new(local_mysql_dump_path, config.local, config.remote).move!
        else
          File.open(local_mysql_dump_path, 'a') do |file|
            file.write "UPDATE wp_options SET option_value=\"#{config.remote.vhost}\" WHERE option_name=\"siteurl\" OR option_name=\"home\";\n"
          end
        end
      end

      remotely do |host|
        host.download_file local_mysql_dump_path, remote_mysql_dump_path
        host.run "mysql", "--user=#{config.remote.database.username}", "--password=#{config.remote.database.password}", "--host=#{config.remote.database.host}", "--database=#{config.remote.database.name}", :stdin => remote_mysql_dump_path
        host.run "rm", remote_mysql_dump_path
      end

      locally do |host|
        host.run "rm", local_mysql_dump_path
      end
    end


    def pull_db
      local_mysql_dump_path = local_wpcontent_path("database_dump.sql")
      remote_mysql_dump_path = remote_wpcontent_path("database_dump.sql")

      remotely do |host|
        host.run "mysqldump", "--host=#{config.remote.database.host}", "--user=#{config.remote.database.username}", "--password=#{config.remote.database.password}", config.remote.database.name, :stdout => remote_mysql_dump_path
        host.upload_file remote_mysql_dump_path, local_mysql_dump_path
      end

      locally do |host|
        if options.adapt_sql
          Wordmove::SqlMover.new(local_mysql_dump_path, config.remote, config.local).move!
        else
          File.open(local_mysql_dump_path, 'a') do |file|
            file.write "UPDATE wp_options SET option_value=\"#{config.local.vhost}\" WHERE option_name=\"siteurl\" OR option_name=\"home\";\n"
          end
        end
        host.run "mysql", "--user=#{config.local.database.username}", "--password=#{config.local.database.password}", "--host=#{config.local.database.host}", "--database=#{config.local.database.name}", :stdin => local_mysql_dump_path
        host.run "rm", local_mysql_dump_path
      end

      remotely do |host|
        host.run "rm", remote_mysql_dump_path
      end

    end

    def config
      if @config.blank?
        config_path = @options[:config] || "Movefile"
        unless File.exists? config_path
          raise Thor::Error, "Could not find a valid Movefile"
        end
        @config = Hashie::Mash.new(YAML::load(File.open(config_path)))
      end
      @config
    end

    def local_wpcontent_path(*args)
      File.join(config.local.wordpress_path, "wp-content", *args)
    end

    def remote_wpcontent_path(*args)
      File.join(config.remote.wordpress_path, "wp-content", *args)
    end

    def locally
      host = LocalHost.new(config.local.merge(:logger => @logger))
      yield host
      host.close
    end

    def remotely
      host = RemoteHost.new(config.remote.merge(:logger => @logger))
      yield host
      host.close
    end

    def informative_errors
      yield
    rescue Timeout::Error
      logger.error "Connection timed out!"
      puts "Timed out"
    rescue Errno::EHOSTUNREACH
      logger.error "Host unreachable!"
    rescue Errno::ECONNREFUSED
      logger.error "Connection refused!"
    rescue Net::SSH::AuthenticationFailed
      logger.error "SSH authentification failure, please double check the SSH credentials on your Movefile!"
    end

  end
end
