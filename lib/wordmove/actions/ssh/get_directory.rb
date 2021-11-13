module Wordmove
  module Actions
    module Ssh
      # Syncs a whole directory over SSH protocol from the remote server to local host
      class GetDirectory
        extend LightService::Action
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers
        include WordpressDirectory::RemoteHelperMethods

        # :folder_task is expected to be one symbol from Wordmove::CLI.wordpress_options array
        expects :logger,
                :local_options,
                :remote_options,
                :cli_options,
                :photocopier,
                :folder_task

        # @!method execute
        # @param logger [Wordmove::Logger]
        # @param local_options [Hash] Local host options fetched from
        #        movefile (with symbolized keys)
        # @param remote_options [Hash] Remote host options fetched from
        #        movefile (with symbolized keys)
        # @param cli_options [Hash] Command line options (with symbolized keys)
        # @param photocopier [Photocopier::SSH]
        # @param folder_task [Symbol] Symbolazied folder name
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context|
          context.logger.task "Pulling #{context.folder_task}"

          next context if simulate?(cli_options: context.cli_options)

          command = 'get_directory'
          # For this action `local_path` and `remote_path` will always be
          # `:wordpress_path`; specific folder for `context.folder_task` will be included by
          # `pull_include_paths`
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
            remote_path,
            local_path,
            pull_exclude_paths(
              remote_task_dir: send(
                "remote_#{context.folder_task}_dir",
                remote_options: context.remote_options
              ),
              paths_to_exclude: paths_to_exclude(remote_options: context.remote_options)
            ),
            pull_include_paths(remote_task_dir: send(
              "remote_#{context.folder_task}_dir",
              remote_options: context.remote_options
            ))
          ]

          context.logger.task_step false, "#{command}: #{command_args.join(' ')}"
          result = context.photocopier.send(command, *command_args)

          next context if result == true

          context.fail!("Failed to push #{context.folder_task}")
        end
      end
    end
  end
end
