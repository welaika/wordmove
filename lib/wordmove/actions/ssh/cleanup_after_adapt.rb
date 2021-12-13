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
        executed do |context|
          context.logger.task 'Cleanup'

          if simulate?(cli_options: context.cli_options)
            context.logger.info 'No cleanup during simulation'
            next context
          end

          Wordmove::Actions::DeleteLocalFile.execute(
            logger: context.logger,
            cli_options: context.cli_options,
            file_path: context.db_paths.local.path
          )

          Wordmove::Actions::DeleteLocalFile.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            file_path: context.db_paths.local.gzipped_adapted_path
          )
        end
      end
    end
  end
end
