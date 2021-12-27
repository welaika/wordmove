module Wordmove
  module Actions
    module Ssh
      # Uploads a DB dump to remote host and import it in the remote database over SSH protocol
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

          context.logger.task 'Upload and import adapted DB'

          result = Wordmove::Actions::PutFile.execute(
            logger: context.logger,
            photocopier: context.photocopier,
            cli_options: context.cli_options,
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
            command: uncompress_command(file_path: context.db_paths.remote.gzipped_path)
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            photocopier: context.photocopier,
            command: mysql_import_command(
              dump_path: context.db_paths.remote.path,
              env_db_options: context.remote_options[:database]
            )
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            cli_options: context.cli_options,
            remote_file: context.db_paths.remote.path
          )
          context.fail!(result.message) if result.failure?
        end
      end
    end
  end
end
