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
          context.logger.task 'Pull remote DB'

          next context if simulate?(cli_options: context.cli_options)

          result = Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            photocopier: context.photocopier,
            logger: context.logger,
            command: mysql_dump_command(
              env_db_options: context.remote_options[:database],
              save_to_path: context.db_paths.remote.path
            )
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            photocopier: context.photocopier,
            logger: context.logger,
            command: compress_command(file_path: context.db_paths.remote.path)
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::GetFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [
              context.db_paths.remote.gzipped_path,
              context.db_paths.local.gzipped_path
            ]
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            remote_file: context.db_paths.remote.gzipped_path
          )
          context.fail!(result.message) if result.failure?
        end
      end
    end
  end
end
