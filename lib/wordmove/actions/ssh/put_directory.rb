module Wordmove
  module Actions
    module Ssh
      class PutDirectory
        extend LightService::Action
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers
        include WordpressDirectory::LocalHelperMethods
        # :folder_task is expected to be one symbol from Wordmove::CLI.wordpress_options array
        expects :logger,
                :local_options,
                :remote_options,
                :photocopier,
                :folder_task

        executed do |context|
          context.logger.task "Pushing #{context.folder_task}"

          command = 'put_directory'
          local_path = context.local_options[:wordpress_path]
          remote_path = context.remote_options[:wordpress_path]

          # This action can generate `command_args` by itself,
          # but it gives the context the chance to ovveride it.
          # By the way this variable is not `expects`ed.
          # Note that we do not use the second argument to `fetch`
          # to express a default value, because it would be greedly interpreted
          # but if `command_args` is already defined by context, then it's
          # possible that `"remote_#{context.folder_task}_dir"` could
          # not be defined.
          command_args = context.fetch(:command_args) || [
            local_path,
            remote_path,
            push_exclude_paths(
              local_task_dir: send(
                "local_#{context.folder_task}_dir",
                local_options: context.local_options
              ),
              paths_to_exclude: paths_to_exclude(remote_options: context.remote_options)
            ),
            push_include_paths(local_task_dir: send(
              "local_#{context.folder_task}_dir",
              local_options: context.local_options
            ))
          ]

          context.logger.task_step false, "#{command}: #{command_args.join(' ')}"
          context.photocopier.send(command, *command_args)
        end
      end
    end
  end
end
