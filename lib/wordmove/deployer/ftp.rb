require 'wordmove/deployer/base'
require 'photocopier/ftp'
require 'erb'
require 'open-uri'

module Wordmove
  module Deployer
    class FTP < Base

      def initialize(environment, options)
        super
        ftp_options = remote_options[:ftp]
        @copier = Photocopier::FTP.new(ftp_options).tap { |c| c.logger = logger }
      end

      def push_db
        super

        local_dump_path = local_wp_content_dir.path("dump.sql")
        remote_dump_path = remote_wp_content_dir.path("dump.sql")
        local_backup_path = local_wp_content_dir.path("remote-backup-#{Time.now.to_i}.sql")

        download_remote_db(local_backup_path)
        save_local_db(local_dump_path)

        # gsub sql
        adapt_sql(local_dump_path, local_options, remote_options)
        # upload it
        remote_put(local_dump_path, remote_dump_path)

        import_remote_dump

        # remove dump remotely
        remote_delete(remote_dump_path)
        # and locally
        run "rm \"#{local_dump_path}\""
      end

      def pull_db
        super
        local_dump_path = local_wp_content_dir.path("dump.sql")
        local_backup_path = local_wp_content_dir.path("local-backup-#{Time.now.to_i}.sql")

        save_local_db(local_backup_path)
        download_remote_db(local_dump_path)

        # gsub sql
        adapt_sql(local_dump_path, remote_options, local_options)
        # import locally
        run mysql_import_command(local_dump_path, local_options[:database])

        # and locally
        run "rm \"#{local_dump_path}\""
      end

      private

      %w(get get_directory put_directory delete).each do |command|
        define_method "remote_#{command}" do |*args|
          logger.task_step false, "#{command}: #{args.join(" ")}"
          unless simulate?
            @copier.send(command, *args)
          end
        end
      end

      def remote_put(thing, path)
        if File.exists?(thing)
          logger.task_step false, "copying #{thing} to #{path}"
        else
          logger.task_step false, "write #{path}"
        end
        unless simulate?
          @copier.put(thing, path)
        end
      end

      def escape_php(string)
        return '' unless string

        # replaces \ with \\
        # replaces ' with \'
        string.gsub('\\','\\\\\\').gsub(/[']/, '\\\\\'')
      end

      def generate_dump_script(db, password)
        template = ERB.new File.read(File.join(File.dirname(__FILE__), "../assets/dump.php.erb"))
        template.result(binding)
      end

      def generate_import_script(db, password)
        template = ERB.new File.read(File.join(File.dirname(__FILE__), "../assets/import.php.erb"))
        template.result(binding)
      end

      def download_remote_db(local_dump_path)
        remote_dump_script = remote_wp_content_dir.path("dump.php")
        # generate a secure one-time password
        one_time_password = SecureRandom.hex(40)
        # generate dump script
        dump_script = generate_dump_script(remote_options[:database], one_time_password)
        # upload the dump script
        remote_put(dump_script, remote_dump_script)
        # download the resulting dump (using the password)
        dump_url = "#{remote_wp_content_dir.url("dump.php")}?shared_key=#{one_time_password}"
        download(dump_url, local_dump_path)
        # remove it remotely
        remote_delete(remote_dump_script)
      end

      def import_remote_dump
        temp_path = local_wp_content_dir.path("temp.txt")
        remote_import_script_path = remote_wp_content_dir.path("import.php")
        # generate a secure one-time password
        one_time_password = SecureRandom.hex(40)
        # generate import script
        import_script = generate_import_script(remote_options[:database], one_time_password)
        # upload import script
        remote_put(import_script, remote_import_script_path)
        # run import script
        import_url = "#{remote_wp_content_dir.url("import.php")}?shared_key=#{one_time_password}&start=1&foffset=0&totalqueries=0&fn=dump.sql"
        download(import_url, temp_path)
        run "rm \"#{temp_path}\""
        # remove script remotely
        remote_delete(remote_import_script_path)
      end

    end
  end
end

