module Wordmove
  module Actions
    # Download a single file from the remote server.
    #
    # @note The remote server is already configured inside the Photocopier object
    # @note This action is *not* meant to be organized, but as a standalone one.
    class GetFile
      extend LightService::Action

      expects :photocopier,
              :logger,
              :command_args

      # @!method execute
      #   @param photocopier [Photocopier]
      #   @param logger [Wordmove::Logger]
      #   @param command_args ((String) remote file path, (String) local file path)
      #   @return [LightService::Context] Action's context
      executed do |context|
        command = 'get'

        context.logger.task_step false, "#{command}: #{context.command_args.join(' ')}"
        result = context.photocopier.send(command, *context.command_args)

        next context if result == true

        context.fail! "Failed to download file: #{context.command_args.first}"
      end
    end
  end
end
