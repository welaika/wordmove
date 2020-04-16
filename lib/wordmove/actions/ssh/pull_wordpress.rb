module Wordmove
  module Actions
    module Ssh
      class PullWordpress
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::RemoteHelperMethods
        expects :options
        expects :remote_options
        expects :local_options
        expects :logger
        expects :movefile
        expects :photocopier

        executed do |context|
          context.logger.task "Pulling wordpress core"

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

          Wordmove::Actions::GetDirectory.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [remote_path, local_path, exclude_paths]
          )
        end
      end
    end
  end
end
