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
          result = Wordmove::Actions::PutFile.execute(
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [
              context.db_paths.local.gzipped_adapted_path,
              context.db_paths.remote.gzipped_path
            ]
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [uncompress_command(file_path: context.db_paths.remote.gzipped_path)]
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [mysql_import_command(
              dump_path: context.db_paths.remote.path,
              env_db_options: context.remote_options[:database]
            )]
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [context.db_paths.remote.path]
          )
          context.fail_and_return!(result.message) if result.failure?
        end
      end
    end
  end
end
