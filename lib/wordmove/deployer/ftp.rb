require 'wordmove/deployer/base'
require 'photocopier/ftp'
require 'erb'
require 'open-uri'

module Wordmove
  module Deployer
    class FTP < Base

      def initialize(options)
        super
        ftp_options = options[:remote][:ftp]
        @copier = Photocopier::FTP.new(ftp_options.merge(logger: logger))
      end

      def push_db
        super

        remote_import_script_path = remote_wpcontent_path("import.php")
        local_dump_path = local_wpcontent_path("dump.sql")
        remote_dump_path = remote_wpcontent_path("dump.sql")

        # dump local mysql into file
        run mysql_dump_command(options[:local][:database], local_dump_path)
        # gsub sql
        adapt_sql(local_dump_path, options[:local], options[:remote])
        # upload it
        remote_put(local_dump_path, remote_dump_path)

        # generate a secure one-time password
        one_time_password = SecureRandom.hex(40)
        # generate import script
        import_script = generate_import_script(options[:remote][:database], one_time_password)
        # upload import script
        remote_put(import_script, remote_import_script_path)
        # run import script
        import_url = "#{remote_wpcontent_url("import.php")}?shared_key=#{one_time_password}&start=1&foffset=0&totalqueries=0&fn=dump.sql"
        download(import_url, local_dump_path + "_")

        # remove script remotely
        remote_delete(remote_import_script_path)
        # remove dump remotely
        remote_delete(remote_dump_path)
        # and locally
        run "rm #{local_dump_path}"
      end

      def pull_db
        super

        remote_dump_script = remote_wpcontent_path("dump.php")
        local_dump_path = local_wpcontent_path("dump.sql")

        # generate a secure one-time password
        one_time_password = SecureRandom.hex(40)

        # generate dump script
        dump_script = generate_dump_script(options[:remote][:database], one_time_password)
        # upload the dump script
        remote_put(dump_script, remote_dump_script)
        # download the resulting dump (using the password)
        dump_url = "#{remote_wpcontent_url("dump.php")}?shared_key=#{one_time_password}"
        download(dump_url, local_dump_path)

        # gsub sql
        adapt_sql(local_dump_path, options[:remote], options[:local])
        # import locally
        run mysql_import_command(local_dump_path, options[:local][:database])

        # remove it remotely
        remote_delete(remote_dump_script)
        # and locally
        run "rm #{local_dump_path}"
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

    end
  end
end

