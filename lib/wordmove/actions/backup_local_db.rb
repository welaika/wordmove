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
        next context if context.database_task == false

        context.logger.task 'Backup local DB'

        if simulate?(cli_options: context.cli_options)
          context.logger.info 'A backup of the local DB would have been saved into ' \
                              "#{context.db_paths.backup.local.gzipped_path}, " \
                              'but you\'re simulating'
          next context
        end

        result = Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,
          logger: context.logger,
          command: mysql_dump_command(
            env_db_options: context.local_options[:database],
            save_to_path: context.db_paths.backup.local.path
          )
        )
        context.fail_and_return!(result.message) if result.failure?

        result = Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,
          logger: context.logger,
          command: compress_command(file_path: context.db_paths.backup.local.path)
        )
        context.fail_and_return!(result.message) if result.failure?

        context.logger.success(
          "Backup saved at #{context.db_paths.backup.local.gzipped_path}"
        )
      end
    end
  end
end
