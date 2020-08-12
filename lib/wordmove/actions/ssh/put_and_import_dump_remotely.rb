module Wordmove
  module Actions
    module Ssh
      class PutAndImportDumpRemotely
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::RemoteHelperMethods
        include WordpressDirectory::LocalHelperMethods

        expects :remote_options,
                :cli_options,
                :logger,
                :photocopier,
                :db_paths

        executed do |context| # rubocop:disable Metrics/BlockLength
          Wordmove::Actions::PutFile(
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [
              context.db_paths.local.gzipped_path,
              context.db_paths.remote.gizipped_path
            ]
          )

          Wordmove::Actions::Ssh::RunRemoteCommand(
            cli_options: context.cli_options,
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [uncompress_command(file_path: context.db_paths.remote.gizipped_path)]
          )

          Wordmove::Actions::Ssh::RunRemoteCommand(
            cli_options: context.cli_options,
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [mysql_import_command(
              context.db_paths.remote.path, context.remote_options[:database]
            )]
          )

          Wordmove::Actions::DeleteRemoteFile(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [context.db_paths.remote.path]
          )
        end
      end
    end
  end
end
