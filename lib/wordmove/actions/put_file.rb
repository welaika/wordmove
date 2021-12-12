module Wordmove
  module Actions
    # Upload a single file to the remote server.
    #
    # @note The remote server is already configured inside the Photocopier object
    # @note This action is *not* meant to be organized, but as a standalone one.
    class PutFile
      extend LightService::Action
      include Wordmove::Actions::Helpers

      expects :photocopier,
              :logger,
              :command_args,
              :cli_options

      # @!method execute
      #   @param photocopier [Photocopier]
      #   @param logger [Wordmove::Logger]
      #   @param command_args ((String) local file path, (String) remote file path)
      #   @return [LightService::Context] Action's context
      executed do |context|
        command = 'put'

        # First argument could be a file or a content string. Do not log if the latter
        message = if File.exist?(context.command_args.first)
                    context.command_args.join(' ')
                  else
                    context.command_args.second
                  end

        context.logger.task_step false, "#{command}: #{message}"

        if simulate?(cli_options: context.cli_options)
          result = true
        else
          result = context.photocopier.send(command, *context.command_args)
        end

        next context if result == true
        # We can't trust the return from the fotocopier method when using FTP.  Keep on
        # and have faith.
        next context if context.photocopier.is_a? Photocopier::FTP

        context.fail! "Failed to upload file: #{context.command_args.first}"
      end
    end
  end
end
