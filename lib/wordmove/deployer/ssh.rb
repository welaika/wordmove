module Wordmove
  module Deployer
    class SSH < Base
      def initialize(environment, options)
        super
        ssh_options = remote_options[:ssh]
        @copier = Photocopier::SSH.new(ssh_options).tap { |c| c.logger = logger }
      end

      protected

      def push_db
        super
      end

      def pull_db
        super
      end

      private

      %w(get put get_directory put_directory delete).each do |command|
        define_method "remote_#{command}" do |*args|
          logger.task_step false, "#{command}: #{args.join(' ')}"
          @copier.send(command, *args) unless simulate?
        end
      end

      def remote_run(command)
        logger.task_step false, command
        unless simulate?
          _stdout, stderr, exit_code = @copier.exec! command
          raise(
            ShellCommandError,
            "Error code #{exit_code} returned by command \"#{command}\": #{stderr}"
          ) unless exit_code.zero?
        end
      end

      def download_remote_db(local_gizipped_dump_path)
        remote_dump_path = remote_wp_content_dir.path("dump.sql")
        # dump remote db into file
        remote_run mysql_dump_command(remote_options[:database], remote_dump_path)
        remote_run compress_command(remote_dump_path)
        remote_dump_path += '.gz'
        # download remote dump
        remote_get(remote_dump_path, local_gizipped_dump_path)
        remote_delete(remote_dump_path)
      end

      def import_remote_dump(local_gizipped_dump_path)
        remote_dump_path = remote_wp_content_dir.path("dump.sql")
        remote_gizipped_dump_path = remote_dump_path + '.gz'

        remote_put(local_gizipped_dump_path, remote_gizipped_dump_path)
        remote_run uncompress_command(remote_gizipped_dump_path)
        remote_run mysql_import_command(remote_dump_path, remote_options[:database])
        remote_delete(remote_dump_path)
      end
    end
  end
end
