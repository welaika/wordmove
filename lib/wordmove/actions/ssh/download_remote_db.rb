module Wordmove
  module Actions
    module Ssh
      class DownloadRemoteDb
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::LocalHelperMethods
        include WordpressDirectory::RemoteHelperMethods

        expects :remote_options,
                :cli_options,
                :logger,
                :photocopier,
                :db_paths

        executed do |context| # rubocop:disable Metrics/BlockLength
          Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [
              mysql_dump_command(
                env_db_options: context.remote_options[:database],
                save_to_path: db_paths.remote.path
              )
            ]
          )

          Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [compress_command(file_path: db_paths.remote.path)]
          )

          Wordmove::Actions::GetFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [db_paths.remote.gzipped_path, db_paths.local.gzipped_path]
          )

          Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [db_paths.remote.gzipped_path]
          )
        end
      end
    end
  end
end
