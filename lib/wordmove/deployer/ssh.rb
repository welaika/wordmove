require 'wordmove/deployer/base'
require 'photocopier/ssh'

module Wordmove
  module Deployer
    class SSH < Base
      def initialize(environment, options)
        super
        ssh_options = remote_options[:ssh]
        @copier = Photocopier::SSH.new(ssh_options).tap { |c| c.logger = logger }
      end

      def push_db
        super

        local_dump_path = local_wp_content_dir.path("dump.sql")
        local_backup_path = local_wp_content_dir.path("#{environment}-backup-#{Time.now.to_i}.sql")
        download_remote_db(local_backup_path)

        save_local_db(local_dump_path)
        adapt_sql(local_dump_path, local_options, remote_options)
        import_remote_dump(local_dump_path)
        run "rm \"#{local_dump_path}\""
      end

      def pull_db
        super

        local_dump_path = local_wp_content_dir.path("dump.sql")
        local_backup_path = local_wp_content_dir.path("local-backup-#{Time.now.to_i}.sql")
        save_local_db(local_backup_path)

        download_remote_db(local_dump_path)
        adapt_sql(local_dump_path, remote_options, local_options)
        run mysql_import_command(local_dump_path, local_options[:database])
        run "rm \"#{local_dump_path}\""
      end

      private

      %w(get put get_directory put_directory delete).each do |command|
        define_method "remote_#{command}" do |*args|
          logger.task_step false, "#{command}: #{args.join(" ")}"
          unless simulate?
            @copier.send(command, *args)
          end
        end
      end

      def remote_run(command)
        logger.task_step false, command
        unless simulate?
          stdout, stderr, exit_code = @copier.exec! command
          raise "Error code #{exit_code} returned by command \"#{command}\": #{stderr}" unless exit_code.zero?
        end
      end

      def download_remote_db(local_dump_path)
        remote_dump_path = remote_wp_content_dir.path("dump.sql")
        # dump remote db into file
        remote_run mysql_dump_command(remote_options[:database], remote_dump_path)
        # download remote dump
        remote_get(remote_dump_path, local_dump_path)
        remote_delete(remote_dump_path)
      end

      def import_remote_dump(local_dump_path)
        remote_dump_path = remote_wp_content_dir.path("dump.sql")
        remote_put(local_dump_path, remote_dump_path)
        remote_run mysql_import_command(remote_dump_path, remote_options[:database])
        remote_delete(remote_dump_path)
      end

    end
  end
end
