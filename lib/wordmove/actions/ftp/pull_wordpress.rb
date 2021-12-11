module Wordmove
  module Actions
    module Ftp
      class PullWordpress
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::RemoteHelperMethods

        expects :remote_options,
                :local_options,
                :logger,
                :movefile,
                :photocopier

        executed do |context|
          local_path = context.local_options[:wordpress_path]

          remote_path = context.remote_options[:wordpress_path]

          wp_content_relative_path = remote_wp_content_dir(
            remote_options: context.remote_options
          ).relative_path

          exclude_wp_content = exclude_dir_contents(
            path: wp_content_relative_path
          )

          exclude_paths = paths_to_exclude(
            remote_options: context.remote_options
          ).push(exclude_wp_content)

          result = Wordmove::Actions::Ftp::GetDirectory.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [remote_path, local_path, exclude_paths],
            folder_task: :wordpress,
            local_options: context.local_options,
            remote_options: context.remote_options
          )
          context.fail!(result.message) if result.failure?
        end
      end
    end
  end
end