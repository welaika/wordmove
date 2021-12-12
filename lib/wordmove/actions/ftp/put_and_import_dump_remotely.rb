module Wordmove
  module Actions
    module Ftp
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

        executed do |context| # rubocop:disable Metrics/BlockLength
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
            Wordmove::Actions::DeleteLocalFile.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              file_path: context.db_paths.ftp.local.temp_path
            )
          end

          result = Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            remote_file: context.db_paths.ftp.remote.import_script_path
          )
          if result.failure?
            context.logger.warning 'Failed to delete remote file ' \
                                  "#{context.db_paths.remote.import_script_path} because: " \
                                  "#{result.message}" \
                                  'Manual intervention required'
          end
        end
      end
    end
  end
end
