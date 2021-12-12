module Wordmove
  module Actions
    module Ftp
      class CleanupAfterAdapt
        extend ::LightService::Action

        expects :db_paths,
                :cli_options,
                :logger,
                :photocopier

        executed do |context|
          Wordmove::Actions::DeleteLocalFile.execute(
            logger: context.logger,
            cli_options: context.cli_options,
            file_path: context.db_paths.local.path
          )

          Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            remote_file: context.db_paths.ftp.remote.dump_script_path
          )
        end
      end
    end
  end
end
