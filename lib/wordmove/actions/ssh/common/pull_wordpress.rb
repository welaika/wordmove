module Wordmove
  module Actions
    module Ssh
      module Common
        class PullWordpress
          extend LightService::Action
          include Wordmove::Actions::Concerns
          expects :options
          expects :photocopier
          expects :logger
          expects :movefile
          promises :command_args

          executed do |context|
            context.logger.task "Pulling wordpress core"

            local_path = local_options(options: context.options)[:wordpress_path]
            remote_path = remote_options(context)[:wordpress_path]
            wp_content_relative_path = WordpressDirectory.new(
              :wp_content,
              remote_options(options: context.options)
            ).relative_path

            exclude_wp_content = exclude_dir_contents(
              path: wp_content_relative_path
            )
            exclude_paths = paths_to_exclude(context).push(exclude_wp_content)

            context.command_args = [remote_path, local_path, exclude_paths]

            Wordmove::Actions::GetDirectory.execute(context)
          end
        end
      end
    end
  end
end
