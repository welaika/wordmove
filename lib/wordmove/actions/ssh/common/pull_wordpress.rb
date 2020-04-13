module Wordmove
  module Actions
    module Ssh
      module Common
        class PullWordpress
          extend ::LightService::Action
          include Wordmove::Actions::Helpers
          expects :options
          expects :logger
          expects :movefile
          expects :guardian
          promises :command_args

          executed do |context|
            context.logger.task "Pulling wordpress core"

            local_path = local_options(options: context.options)[:wordpress_path]
            remote_path = remote_options(
              options: context.options, movefile: context.movefile
            )[:wordpress_path]
            wp_content_relative_path = WordpressDirectory.new(
              :wp_content,
              remote_options(options: context.options, movefile: context.movefile)
            ).relative_path

            exclude_wp_content = exclude_dir_contents(
              path: wp_content_relative_path
            )
            exclude_paths = paths_to_exclude(
              options: context.options, movefile: context.movefile
            ).push(exclude_wp_content)

            context.command_args = [remote_path, local_path, exclude_paths]

            Wordmove::Actions::GetDirectory.execute(context)
          end
        end
      end
    end
  end
end
