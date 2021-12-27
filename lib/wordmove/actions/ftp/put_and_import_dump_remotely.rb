module Wordmove
  module Actions
    module Ftp
      # Uploads a DB dump to remote host and import it in the remote database over FTP protocol
      class PutAndImportDumpRemotely
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ftp::Helpers
        include WordpressDirectory::RemoteHelperMethods
        include WordpressDirectory::LocalHelperMethods

        expects :remote_options,
                :cli_options,
                :logger,
                :photocopier,
                :db_paths

        # @!method execute
        # @param logger [Wordmove::Logger]
        # @param cli_options [Hash] Command line options (with symbolized keys)
        # @param remote_options [Hash] Remote host options fetched from
        #        movefile (with symbolized keys)
        # @param db_paths [BbPathsConfig] Configuration object for database
        # @param photocopier [Photocopier::FTP]
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
              context.db_paths.local.adapted_path,
              context.db_paths.remote.path
            ]
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::PutFile.execute(
            logger: context.logger,
            photocopier: context.photocopier,
            cli_options: context.cli_options,
            command_args: [
              context.db_paths.ftp.local.generated_import_script_path,
              context.db_paths.ftp.remote.import_script_path
            ]
          )
          context.fail_and_return!(result.message) if result.failure?

          import_url = [
            context.db_paths.ftp.remote.import_script_url,
            '?shared_key=',
            context.db_paths.ftp.token,
            '&start=1&foffset=0&totalqueries=0&fn=dump.sql'
          ].join

          download(url: import_url, local_path: context.db_paths.ftp.local.temp_path)

          if context.cli_options[:debug]
            context.logger.debug "Operation log located at: #{context.db_paths.ftp.local.temp_path}"
          else
            result = Wordmove::Actions::DeleteLocalFile.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              file_path: context.db_paths.ftp.local.temp_path
            )

            if result.failure?
              context.logger.warning 'Failed to delete local file ' \
                                     "#{context.db_paths.ftp.local.temp_path} because: " \
                                     "#{result.message}" \
                                     '. Manual intervention required'
            end
          end
        end
      end
    end
  end
end
