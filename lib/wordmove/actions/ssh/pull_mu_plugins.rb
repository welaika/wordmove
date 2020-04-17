module Wordmove
  module Actions
    module Ssh
      class PullMuPlugins
        extend ::LightService::Action
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers
        include WordpressDirectory::RemoteHelperMethods
        expects :logger
        expects :local_options
        expects :remote_options
        expects :current_task
        expects :photocopier

        executed do |context|
          context.logger.task "Pulling #{context.current_task.to_s.titleize}"
          local_path = context.local_options[:wordpress_path]
          remote_path = context.remote_options[:wordpress_path]
          remote_task_dir = remote_mu_plugins_dir(remote_options: context.remote_options)

          Wordmove::Actions::GetDirectory.execute(
            photocopier: context.photocopier,
            logger: context.logger,
            command_args: [
              remote_path,
              local_path,
              pull_exclude_paths(
                remote_task_dir: remote_task_dir,
                paths_to_exclude: paths_to_exclude(remote_options: context.remote_options)
              ),
              pull_include_paths(remote_task_dir: remote_task_dir)
            ]
          )
        end
      end
    end
  end
end
