module Wordmove
  module Actions
    module Ftp
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

        executed do |context|
          next context if simulate?(cli_options: context.cli_options)

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
            context.fail_and_return!(e.message)
          ensure
            Wordmove::Actions::DeleteRemoteFile.execute(
              photocopier: context.photocopier,
              logger: context.logger,
              remote_file: context.db_paths.ftp.remote.dumped_path
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
end
