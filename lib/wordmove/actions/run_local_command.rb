require 'English'

module Wordmove
  module Actions
    # Run a command on the local system.
    # Command won't be run if +--simulate+ flag is present on CLI.
    # @note This action is *not* meant to be organized, but as a standalone one.
    class RunLocalCommand
      extend LightService::Action
      include Wordmove::Actions::Helpers

      expects :command,
              :cli_options,
              :logger

      # @!method execute
      #   @param command [String] The command to run
      #   @param cli_options [Hash]
      #   @param logger [Wordmove::Logger]
      #   @return [LightService::Context] Action's context
      executed do |context|
        context.logger.task_step true, context.command

        next context if simulate?(cli_options: context.cli_options)

        begin
          system(context.command, exception: true)
        rescue RuntimeError, SystemExit => e
          context.fail!("Local command status reports an error: #{e.message}")
        end
      end
    end
  end
end
