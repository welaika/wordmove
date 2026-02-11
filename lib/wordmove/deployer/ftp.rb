module Wordmove
  module Deployer
    class FTP < Base
      def initialize(environment, options)
        super(environment, options)
        ftp_options = remote_options[:ftp]
        @copier = Photocopier::FTP.new(ftp_options).tap { |c| c.logger = logger }
      end

      def push_db
        super

        return true if simulate?

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
        local_delete(local_dump_path)
      end

      def pull_db
        super

        return true if simulate?

        local_dump_path = local_wp_content_dir.path("dump.sql")
        local_backup_path = local_wp_content_dir.path("local-backup-#{Time.now.to_i}.sql")

        save_local_db(local_backup_path)
        download_remote_db(local_dump_path)

        # gsub sql
        adapt_sql(local_dump_path, remote_options, local_options)
        # import locally
        run mysql_import_command(local_dump_path, local_options[:database])

        # and locally
        if options[:debug]
          logger.debug "Remote dump located at: #{local_dump_path}"
        else
          local_delete(local_dump_path)
        end
      end

      private

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

      %w[get get_directory put_directory delete].each do |command|
        define_method "remote_#{command}" do |*args|
          logger.task_step false, "#{command}: #{args.join(' ')}"
          @copier.send(command, *args) unless simulate?
        end
      end

      def remote_put(thing, path)
        if File.exist?(thing)
          logger.task_step false, "copying #{thing} to #{path}"
        else
          logger.task_step false, "write #{path}"
        end
        @copier.put(thing, path) unless simulate?
      end

      def escape_php(string)
        return '' unless string

        # replaces \ with \\
        # replaces ' with \'
        string.gsub('\\', '\\\\\\').gsub(/'/, '\\\\\'')
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
        dump_url = "#{remote_wp_content_dir.url('dump.php')}?shared_key=#{one_time_password}"
        download(dump_url, local_dump_path)
        # cleanup remotely
        remote_delete(remote_dump_script)
        remote_delete(remote_wp_content_dir.path("dump.mysql"))
      end

      def import_remote_dump
        temp_path = local_wp_content_dir.path("log.html")
        remote_import_script_path = remote_wp_content_dir.path("import.php")
        # generate a secure one-time password
        one_time_password = SecureRandom.hex(40)
        # generate import script
        import_script = generate_import_script(remote_options[:database], one_time_password)
        # upload import script
        remote_put(import_script, remote_import_script_path)
        # run import script
        import_url = [
          remote_wp_content_dir.url('import.php').to_s,
          "?shared_key=#{one_time_password}",
          "&start=1&foffset=0&totalqueries=0&fn=dump.sql"
        ].join
        download(import_url, temp_path)
        if options[:debug]
          logger.debug "Operation log located at: #{temp_path}"
        else
          local_delete(temp_path)
        end
        # remove script remotely
        remote_delete(remote_import_script_path)
      end

      def adapt_sql(save_to_path, local, remote)
        return if options[:no_adapt]

        logger.task_step true, "Adapt dump"
        SqlAdapter::Default.new(save_to_path, local, remote).adapt! unless simulate?
      end
    end
  end
end
