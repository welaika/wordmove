require 'wordmove/deployer/base'
require 'photocopier/ssh'

module Wordmove
  module Deployer
    class SSH < Base
      def initialize(options)
        super
        ssh_options = options[:remote][:ssh]
        @copier = Photocopier::SSH.new(ssh_options.merge(logger: logger))
      end

      def push_db
        super

        local_dump_path = local_wpcontent_path("dump.sql")
        remote_dump_path = remote_wpcontent_path("dump.sql")

        # dump local mysql into file
        run mysql_dump_command(options[:local][:database], local_dump_path)
        # gsub sql
        adapt_sql(local_dump_path, options[:local], options[:remote])
        # upload it
        remote_put(local_dump_path, remote_dump_path)
        # import it remotely
        remote_run mysql_import_command(remote_dump_path, options[:remote][:database])
        # remove it remotely
        remote_delete(remote_dump_path)
        # and locally
        run "rm #{local_dump_path}"
      end

      def pull_db
        super

        local_dump_path = local_wpcontent_path("dump.sql")
        remote_dump_path = remote_wpcontent_path("dump.sql")

        # dump remote db into file
        remote_run mysql_dump_command(options[:remote][:database], remote_dump_path)
        # download remote dump
        remote_get(remote_dump_path, local_dump_path)
        # gsub sql
        adapt_sql(local_dump_path, options[:remote], options[:local])
        # import locally
        run mysql_import_command(local_dump_path, options[:local][:database])
        # remove it remotely
        remote_delete(remote_dump_path)
        # and locally
        run "rm #{local_dump_path}"
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
          @copier.session.exec! command
        end
      end

    end
  end
end
