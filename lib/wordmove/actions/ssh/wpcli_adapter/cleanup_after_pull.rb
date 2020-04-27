module Wordmove
  module Actions
    module Ssh
      class CleanupAfterPull
        extend ::LightService::Action
        expects :local_dump_path,
                :cli_options,
                :logger

        executed do |context|
          Wordmove::Actions::DeleteLocalFile.execute(
            logger: context.logger,
            cli_options: context.cli_options,
            file_path: context.local_dump_path
          )
        end
      end
    end
  end
end
