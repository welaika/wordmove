module Wordmove
  module Actions
    #
    # Take a backup of the local database and save it in +wp-content/+ folder.
    #
    class BackupLocalDb
      extend ::LightService::Action
      include Wordmove::Actions::Helpers

      expects :local_options
      expects :cli_options
      expects :db_paths
      expects :logger

      # @!method execute
      # @param local_options [Hash] Local host options fetched from
      #        movefile (with symbolized keys)
      # @param cli_options [Hash] Command line options
      # @param db_paths [BbPathsConfig] Configuration object for database
      # @param logger [Wordmove::Logger]
      # @!scope class
      # @return [LightService::Context] Action's context
      executed do |context|
        context.logger.task 'Backup local DB'

        if simulate?(cli_options: context.cli_options)
          context.logger.info 'A backup of the local DB would have been saved into ' \
                              "#{context.db_paths.backup.local.gzipped_path}, " \
                              'but you\'re simulating'
          next context
        end

        context.logger.task_step true, dump_command(context)

        begin
          system(dump_command(context), exception: true)
        rescue RuntimeError, SystemExit => e
          context.fail_and_return!("Local command status reports an error: #{e.message}")
        end

        context.logger.task_step true, compress_command(context)

        begin
          system(compress_command(context), exception: true)
        rescue RuntimeError, SystemExit => e
          context.fail_and_return!("Local command status reports an error: #{e.message}")
        end

        context.logger.success(
          "Backup saved at #{context.db_paths.backup.local.gzipped_path}"
        )
      end

      def self.dump_command(context)
        "wp db export #{context.db_paths.backup.local.path} --allow-root --quiet"
      end

      def self.compress_command(context)
        command = ['nice']
        command << '-n'
        command << '0'
        command << 'gzip'
        command << '-9'
        command << '-f'
        command << "\"#{context.db_paths.backup.local.path}\""
        command.join(' ')
      end
    end
  end
end
