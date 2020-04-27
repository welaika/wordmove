module Wordmove
  module Actions
    module Ssh
      class DownloadRemoteDb
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::LocalHelperMethods
        include WordpressDirectory::RemoteHelperMethods
        expects :remote_options
        expects :local_options
        expects :cli_options
        expects :logger
        expects :movefile
        expects :photocopier

        executed do |context| # rubocop:disable Metrics/BlockLength
          local_dump_path = local_wp_content_dir(
            local_options: context.local_options
          ).path('dump.sql')
          local_gzipped_dump_path = local_dump_path + '.gz'

          remote_dump_path = remote_wp_content_dir(
            remote_options: context.remote_options
          ).path("dump.sql")

          Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [
              mysql_dump_command(
                env_db_options: context.remote_options[:database],
                save_to_path: remote_dump_path
              )
            ]
          )

          Wordmove::Actions::Ssh::RunRemoteCommand.execute(
            cli_options: context.cli_options,
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [compress_command(file_path: remote_dump_path)]
          )

          remote_dump_path += '.gz'

          Wordmove::Actions::GetFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [remote_dump_path, local_gzipped_dump_path]
          )

          Wordmove::Actions::DeleteRemoteFile.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [remote_dump_path]
          )
        end
      end
    end
  end
end
