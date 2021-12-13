module Wordmove
  module Actions
    module Ftp
      # Cleanup file created during DB push/pull operations
      class CleanupAfterAdapt
        extend ::LightService::Action
        include Wordmove::Actions::Helpers

        expects :db_paths,
                :cli_options,
                :logger,
                :photocopier

        # @!method execute
        # @param logger [Wordmove::Logger]
        # @param cli_options [Hash] Command line options (with symbolized keys)
        # @param db_paths [BbPathsConfig] Configuration object for database
        # @param photocopier [Photocopier::FTP]
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context| # rubocop:disable Metrics/BlockLength
          context.logger.task 'Cleanup'

          if simulate?(cli_options: context.cli_options)
            context.logger.info 'No cleanup during simulation'
            next context
          end

          result = Wordmove::Actions::DeleteLocalFile.execute(
            logger: context.logger,
            cli_options: context.cli_options,
            file_path: context.db_paths.local.path
          )

          if result.failure?
            context.logger.warning 'Failed to delete remote file ' \
                                  "#{context.db_paths.local.path} because: " \
                                  "#{result.message}" \
                                  '. Manual intervention required'
          end

          [
            context.db_paths.ftp.remote.dump_script_path,
            context.db_paths.ftp.remote.import_script_path,
            context.db_paths.remote.path,
            context.db_paths.ftp.remote.dumped_path
          ].each do |file|
            begin
              result = Wordmove::Actions::DeleteRemoteFile.execute(
                photocopier: context.photocopier,
                logger: context.logger,
                cli_options: context.cli_options,
                remote_file: file
              )
            rescue Net::FTPPermError => _e
              context.logger.info "#{file} doesn't exist remotely. Nothing to cleanup"
            end

            if result.failure? # rubocop:disable Style/Next
              context.logger.warning 'Failed to delete remote file ' \
                                    "#{file} because: " \
                                    "#{result.message}" \
                                    '. Manual intervention required'
            end
          end
        end
      end
    end
  end
end
