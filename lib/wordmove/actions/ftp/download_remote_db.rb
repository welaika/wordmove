module Wordmove
  module Actions
    module Ftp
      # Downloads the remote DB over FTP protocol
      class DownloadRemoteDb
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ftp::Helpers
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
        # @param photocopier [Photocopier::FTP]
        # @param db_paths [BbPathsConfig] Configuration object for database
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context| # rubocop:disable Metrics/BlockLength
          context.logger.task 'Download remote DB'

          if simulate?(cli_options: context.cli_options)
            context.logger.info 'A dump of the remote DB would have been saved into ' \
                                "#{context.db_paths.local.path}, " \
                                'but you\'re simulating'
            next context
          end

          result = Wordmove::Actions::PutFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            cli_options: context.cli_options,
            command_args: [
              context.db_paths.ftp.local.generated_dump_script_path,
              context.db_paths.ftp.remote.dump_script_path
            ]
          )
          context.fail_and_return!(result.message) if result.failure?

          dump_url = [
            context.db_paths.ftp.remote.dump_script_url,
            '?shared_key=',
            context.db_paths.ftp.token
          ].join

          begin
            download(url: dump_url, local_path: context.db_paths.local.path)
          rescue => _e # rubocop:disable Style/RescueStandardError
            context.fail!(e.message)
          ensure
            Wordmove::Actions::DeleteRemoteFile.execute(
              photocopier: context.photocopier,
              logger: context.logger,
              cli_options: context.cli_options,
              remote_file: context.db_paths.ftp.remote.dumped_path
            )
            Wordmove::Actions::DeleteRemoteFile.execute(
              photocopier: context.photocopier,
              logger: context.logger,
              cli_options: context.cli_options,
              remote_file: context.db_paths.ftp.remote.dump_script_path
            )
          end

          unless File.exist? context.db_paths.local.path
            context.fail!('Download of remote DB failed')
          end
        end
      end
    end
  end
end
