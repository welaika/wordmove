module Wordmove
  module Actions
    module Ssh
      class CleanupAfterAdapt
        extend ::LightService::Action

        expects :db_paths,
                :cli_options,
                :logger

        executed do |context|
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
