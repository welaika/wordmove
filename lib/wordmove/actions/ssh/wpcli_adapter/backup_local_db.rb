module Wordmove
  module Actions
    module Ssh
      module WpcliAdapter
        class BackupLocalDb
          extend ::LightService::Action
          include Wordmove::Actions::Helpers
          expects :local_options
          expects :cli_options
          expects :backup_path
          expects :logger

          executed do |context|
            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: mysql_dump_command(
                env_db_options: context.local_options[:database],
                save_to_path: context.backup_path
              )
            )

            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: compress_command(file_path: context.backup_path)
            )
          end
        end
      end
    end
  end
end
