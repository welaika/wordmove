module Wordmove
  module Actions
    module Ssh
      # Downloads the remote DB over SSH protocol
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

        # @!method execute
        # @param remote_options [Hash] Remote host options fetched from
        #        movefile (with symbolized keys)
        # @param cli_options [Hash] Command line options (with symbolized keys)
        # @param logger [Wordmove::Logger]
        # @param photocopier [Photocopier::SSH]
        # @param db_paths [BbPathsConfig] Configuration object for database
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context| # rubocop:disable Metrics/BlockLength
          next context if context.database_task == false

          context.logger.task 'Download remote DB'

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
            cli_options: context.cli_options,
            command_args: [
              context.db_paths.remote.gzipped_path,
              context.db_paths.local.gzipped_path
            ]
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            cli_options: context.cli_options,
            remote_file: context.db_paths.remote.gzipped_path
          )
          context.fail_and_return!(result.message) if result.failure?

          context.logger.success(
            "Remote DB dump downloaded in #{context.db_paths.local.gzipped_path}"
          )
        end
      end
    end
  end
end
