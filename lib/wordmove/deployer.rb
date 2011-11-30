require 'active_support/core_ext'
require 'hashie'
require 'paint/pa'
require 'escape'
require 'net/ssh'
require 'net/scp'

require 'wordmove/hosts/local_host'
require 'wordmove/hosts/remote_host'

module Wordmove

  class Deployer

    def initialize(options = {})
      @options = Hashie::Mash.new(options)
    end

    def push
      %w(db uploads themes plugins).each do |step|
        unless @options["skip_#{step}".to_s]
          pa "Pushing #{step.titleize}...", :cyan
          send "push_#{step}"
        end
      end
    end

    def pull
      %w(db uploads themes plugins).each do |step|
        unless @options["skip_#{step}".to_s]
          pa "Pushing #{step.titleize}...", :cyan
          send "pull_#{step}"
        end
      end
    end

    private

    def push_db
      local_mysql_dump_path = local_wpcontent_path("database_dump.sql")
      remote_mysql_dump_path = remote_wpcontent_path("database_dump.sql")

      locally do |host|
        host.run "mysqldump", "--host=#{config.local.database.host}", "--user=#{config.local.database.username}", "--password=#{config.local.database.password}", config.local.database.name, :stdout => local_mysql_dump_path
        File.open(local_mysql_dump_path, 'a') do |file|
          file.write "UPDATE wp_options SET option_value=\"#{config.remote.vhost}\" WHERE option_name=\"siteurl\" OR option_name=\"home\";\n"
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

    def push_uploads
      remotely do |host|
        host.download_dir local_wpcontent_path("uploads"), remote_wpcontent_path("uploads")
      end
    end

    def push_themes
      remotely do |host|
        host.download_dir local_wpcontent_path("themes"), remote_wpcontent_path("themes")
      end
    end

    def push_plugins
      remotely do |host|
        host.download_dir local_wpcontent_path("plugins"), remote_wpcontent_path("plugins")
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
        File.open(local_mysql_dump_path, 'a') do |file|
          file.write "UPDATE wp_options SET option_value=\"#{config.local.vhost}\" WHERE option_name=\"siteurl\" OR option_name=\"home\";\n"
        end
        host.run "mysql", "--user=#{config.local.database.username}", "--password=#{config.local.database.password}", "--host=#{config.local.database.host}", "--database=#{config.local.database.name}", :stdin => local_mysql_dump_path
        host.run "rm", local_mysql_dump_path
      end

      remotely do |host|
        host.run "rm", remote_mysql_dump_path
      end

    end

    def pull_uploads
      remotely do |host|
        host.upload_dir remote_wpcontent_path("uploads"), local_wpcontent_path("uploads")
      end
    end

    def pull_themes
      remotely do |host|
        host.upload_dir remote_wpcontent_path("themes"), local_wpcontent_path("themes")
      end
    end

    def pull_plugins
      remotely do |host|
        host.upload_dir remote_wpcontent_path("plugins"), local_wpcontent_path("plugins")
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
      host = LocalHost.new(config.local)
      yield host
      host.close
    end

    def remotely
      host = RemoteHost.new(config.remote)
      yield host
      host.close
    end

  end
end
