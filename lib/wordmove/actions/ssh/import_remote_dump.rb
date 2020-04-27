module Wordmove
  module Actions
    module Ssh
      class ImportRemoteDump
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::RemoteHelperMethods
        include WordpressDirectory::LocalHelperMethods
        expects :options
        expects :remote_options
        expects :local_options
        expects :cli_options
        expects :logger
        expects :movefile
        expects :photocopier

        executed do |context| # rubocop:disable Metrics/BlockLength
          local_dump_path = local_wp_content_dir.path("dump.sql")
          local_gzipped_dump_path = local_dump_path + '.gz'

          remote_dump_path = remote_wp_content_dir(
            remote_options: context.remote_options
          ).path("dump.sql")
          remote_gizipped_dump_path = remote_dump_path + '.gz'

          Wordmove::Actions::PutFile(
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [local_gzipped_dump_path, remote_gizipped_dump_path]
          )

          Wordmove::Actions::Ssh::RunRemoteCommand(
            cli_options: context.cli_options,
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [uncompress_command(remote_gizipped_dump_path)]
          )

          Wordmove::Actions::Ssh::RunRemoteCommand(
            cli_options: context.cli_options,
            logger: context.logger,
            photocopier: context.photocopier,
            command_args: [mysql_import_command(
              remote_dump_path, context.remote_options[:database]
            )]
          )

          Wordmove::Actions::DeleteRemoteFile(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [remote_dump_path]
          )
        end
      end
    end
  end
end
