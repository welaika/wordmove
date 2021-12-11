module Wordmove
  module Actions
    module Ftp
      class GetDirectory
        extend LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::RemoteHelperMethods
        include WordpressDirectory::LocalHelperMethods

        # :folder_task is expected to be one symbol from Wordmove::CLI.wordpress_options array
        expects :logger,
                :local_options,
                :remote_options,
                :photocopier,
                :folder_task

        executed do |context|
          context.logger.task "Pulling #{context.folder_task}"

          command = 'get_directory'

          # This action can generate `command_args` by itself,
          # but it gives the context the chance to ovveride it.
          # By the way this variable is not `expects`ed.
          # Note that we do not use the second argument to `fetch`
          # to express a default value, because it would be greedly interpreted
          # but if `command_args` is already defined by context, then it's
          # possible that `"remote_#{context.folder_task}_dir"` could
          # not be defined.
          command_args = context.fetch(:command_args) || [
            send(
              "remote_#{context.folder_task}_dir",
              remote_options: context.remote_options
            ).path,
            send(
              "local_#{context.folder_task}_dir",
              local_options: context.local_options
            ).path,
            paths_to_exclude(remote_options: context.remote_options)
          ]

          context.logger.task_step false, "#{command}: #{command_args.join(' ')}"
          result = context.photocopier.send(command, *command_args)

          next context if result == true

          context.fail!("Failed to pull #{context.folder_task}")
        end
      end
    end
  end
end
