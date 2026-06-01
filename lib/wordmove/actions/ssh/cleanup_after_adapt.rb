module Wordmove
  module Actions
    module Ssh
      # Cleanup file created during DB push/pull operations
      class CleanupAfterAdapt
        extend ::LightService::Action
        include Wordmove::Actions::Helpers

        expects :db_paths,
                :cli_options,
                :logger

        # @!method execute
        # @param db_paths [BbPathsConfig] Configuration object for database
        # @param cli_options [Hash] Command line options (with symbolized keys)
        # @param logger [Wordmove::Logger]
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
            context.logger.warning 'Failed to delete local file ' \
                                   "#{context.db_paths.local.path} because: " \
                                   "#{result.message}" \
                                   '. Manual intervention required'
          end

          result = Wordmove::Actions::DeleteLocalFile.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            file_path: context.db_paths.local.gzipped_adapted_path
          )
          if result.failure?
            context.logger.warning 'Failed to delete local file ' \
                                   "#{context.db_paths.local.gzipped_adapted_path} because: " \
                                   "#{result.message}" \
                                   '. Manual intervention required'
          end
        end
      end
    end
  end
end
