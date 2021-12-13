module Wordmove
  module Actions
    module Ssh
      # Syncs wordpress folder (usually root folder), exluding +wp-content/+ folder, over SSH
      # protocol from the remote server to local host
      class PullWordpress
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::RemoteHelperMethods

        expects :remote_options,
                :local_options,
                :logger,
                :photocopier

        # @!method execute
        # @param remote_options [Hash] Remote host options fetched from
        #        movefile (with symbolized keys)
        # @param local_options [Hash] Local host options fetched from
        #        movefile (with symbolized keys)
        # @param logger [Wordmove::Logger]
        # @param photocopier [Photocopier::SSH]
        # @!scope class
        # @return [LightService::Context] Action's context
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

          result = Wordmove::Actions::Ssh::GetDirectory.execute(
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
