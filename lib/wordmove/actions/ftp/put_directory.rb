module Wordmove
  module Actions
    module Ftp
      # Syncs a whole directory over FTP protocol from local host to remote server
      class PutDirectory
        extend LightService::Action
        include Wordmove::Actions::Helpers
        include WordpressDirectory::LocalHelperMethods
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
        # @param photocopier [Photocopier::FTP]
        # @param folder_task [Symbol] Symbolazied folder name
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context|
          context.logger.task "Pushing #{context.folder_task}"

          next context if simulate?(cli_options: context.cli_options)

          command = 'put_directory'

          # This action can generate `command_args` by itself,
          # but it gives the context the chance to ovveride it.
          # By the way this variable is not `expects`ed.
          # Note that we do not use the second argument to `fetch`
          # to express a default value, because it would be greedly interpreted
          # but if `command_args` is already defined by context, then it's
          # possible that `"local_#{context.folder_task}_dir"` could
          # not be defined.
          command_args = context.fetch(:command_args) || [
            send(
              "local_#{context.folder_task}_dir",
              local_options: context.local_options
            ).path,
            send(
              "remote_#{context.folder_task}_dir",
              remote_options: context.remote_options
            ).path,
            paths_to_exclude(remote_options: context.remote_options)
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
