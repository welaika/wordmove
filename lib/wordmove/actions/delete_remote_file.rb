module Wordmove
  module Actions
    # Delete a remote file
    # @note This action is *not* meant to be organized, but as a standalone one.
    class DeleteRemoteFile
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
        command = 'delete'

        context.logger.task_step false, "#{command}: #{context.command_args.join(' ')}"
        _stdout, stderr, exit_code = context.photocopier.send(command, *context.command_args)

        next context if exit_code.zero?

        context.fail! "Error code #{exit_code} returned while deleting file "\
                      "#{context.command_args.join}: #{stderr}"
      end
    end
  end
end
