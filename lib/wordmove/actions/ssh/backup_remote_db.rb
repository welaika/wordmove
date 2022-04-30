module Wordmove
  module Actions
    module Ssh
      # Bakups an alrady downloaded remote dump
      class BackupRemoteDb
        extend ::LightService::Action
        include Wordmove::Actions::Helpers

        expects :cli_options,
                :logger,
                :db_paths

        # @!method execute
        # @param cli_options [Hash] Command line options (with symbolized keys)
        # @param logger [Wordmove::Logger]
        # @param db_paths [BbPathsConfig] Configuration object for database
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context|
          context.logger.task 'Backup remote DB'

          if simulate?(cli_options: context.cli_options)
            context.logger.info 'A backup of the remote DB would have been saved into ' \
                                "#{context.db_paths.backup.remote.gzipped_path}, " \
                                'but you\'re simulating'
            next context
          end

          # Most of the expectations are needed to be proxied to `DownloadRemoteDb`
          # Wordmove::Actions::Ssh::DownloadRemoteDb.execute(context)
          # DownloadRemoteDB will save the file in `db_paths.local.gzipped_path`

          begin
            FileUtils.mv(
              context.db_paths.local.gzipped_path,
              context.db_paths.backup.remote.gzipped_path
            )

            context.logger.success(
              "Backup saved at #{context.db_paths.backup.remote.gzipped_path}"
            )
          rescue Errno::ENOENT => e
            context.fail_and_return!("Remote DB backup failed with: #{e.message}. Aborting.")
          end
        end
      end
    end
  end
end
