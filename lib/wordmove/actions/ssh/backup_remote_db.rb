module Wordmove
  module Actions
    module Ssh
      # Bakups the remote DB over SSH protocol
      class BackupRemoteDb
        extend ::LightService::Action
        include Wordmove::Actions::Helpers

        expects :remote_options,
                :cli_options,
                :logger,
                :photocopier,
                :db_paths

        # @!method execute
        # @param remote_options [Hash] Options for the remote host fetched from the movefile
        # @param cli_options [Hash] Command line options (with symbolized keys)
        # @param logger [Wordmove::Logger]
        # @param photocopier [Photocopier::SSH]
        # @param db_paths [BbPathsConfig] Configuration object for database
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context|
          context.logger.task 'Backup remote DB'

          # Most of the expectations are needed to be proxied to `DownloadRemoteDb`
          Wordmove::Actions::Ssh::DownloadRemoteDb.execute(context)
          # DownloadRemoteDB will save the file in `db_paths.local.gzipped_path`
          begin
            FileUtils.mv(
              context.db_paths.local.gzipped_path,
              context.db_paths.backup.remote.gzipped_path
            )

            context.logger.task_step(
              true,
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
