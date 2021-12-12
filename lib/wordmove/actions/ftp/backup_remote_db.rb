module Wordmove
  module Actions
    module Ftp
      class BackupRemoteDb
        extend ::LightService::Action
        include Wordmove::Actions::Helpers

        expects :remote_options,
                :cli_options,
                :logger,
                :photocopier,
                :db_paths

        executed do |context|
          context.logger.task 'Backup remote DB'

          # Most of the expectations are needed to be proxied to `DownloadRemoteDb`
          # DownloadRemoteDB will save the file in `db_paths.local.path`
          Wordmove::Actions::Ftp::DownloadRemoteDb.execute(context)

          begin
            result = Wordmove::Actions::RunLocalCommand.execute(
              logger: context.logger,
              cli_options: context.cli_options,
              command: compress_command(file_path: context.db_paths.local.path)
            )
            raise(result.message) if result.failure?

            FileUtils.mv(
              context.db_paths.local.gzipped_path,
              context.db_paths.backup.remote.gzipped_path
            )

            context.logger.info("Backup saved at #{context.db_paths.backup.remote.gzipped_path}")
          rescue Errno::ENOENT, RuntimeError => e
            context.fail_and_return!("Remote DB backup failed with: <#{e.message}>. Aborting.")
          end
        end
      end
    end
  end
end
