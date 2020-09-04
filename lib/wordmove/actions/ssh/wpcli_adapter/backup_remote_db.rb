module Wordmove
  module Actions
    module Ssh
      module WpcliAdapter
        class BackupRemoteDb
          extend ::LightService::Action
          include Wordmove::Actions::Helpers

          expects :remote_options,
                  :cli_options,
                  :logger,
                  :photocopier,
                  :db_paths

          executed do |context|
            # Most of the expectations are needed to be proxied to `DownloadRemoteDb`
            Wordmove::Actions::Ssh::DownloadRemoteDb.execute(context)
            # DownloadRemoteDB will save the file in `db_paths.local.gzipped_path`
            begin
              FileUtils.mv(
                context.db_paths.local.gzipped_path,
                context.db_paths.backup.remote.gzipped_path
              )
            rescue Errno::ENOENT => e
              context.fail_and_return! e.massage
            end
          end
        end
      end
    end
  end
end
