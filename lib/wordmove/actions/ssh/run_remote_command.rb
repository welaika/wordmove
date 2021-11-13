module Wordmove
  module Actions
    module Ssh
      # Run a command on a remote host using Photocopier
      #
      # @note The remote server is already configured inside the Photocopier object
      # @note This action is *not* meant to be organized, but as a standalone one.
      class RunRemoteCommand
        extend LightService::Action
        include Wordmove::Actions::Helpers

        expects :photocopier,
                :logger,
                :cli_options,
                :command

        # @!method execute
        # @param photocopier [Photocopier]
        # @param logger [Wordmove::Logger]
        # @param cli_options [Hash] The hash of command line options
        # @param command [String] the command to run
        # @!scope class
        # @return [LightService::Context] Action's context
        executed do |context|
          context.logger.task_step false, context.command

          next context if simulate?(cli_options: context.cli_options)

          _stdout, stderr, exit_code = context.photocopier.exec!(context.command)

          next context if exit_code.zero?

          context.fail! "Error code #{exit_code} returned by command "\
                        "#{context.command}: #{stderr}"
        end
      end
    end
  end
end
