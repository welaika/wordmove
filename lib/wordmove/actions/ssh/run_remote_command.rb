module Wordmove
  module Actions
    module Ssh
      class RunRemoteCommand
        extend LightService::Action
        include Wordmove::Actions::Helpers
        expects :photocopier
        expects :logger
        expects :command_args
        expects :cli_options

        executed do |context|
          context.logger.task_step false, *context.command_args

          next context if simulate?(cli_options: context.cli_options)

          _stdout, stderr, exit_code = context.photocopier.exec!(*context.command_args)

          next context if exit_code.zero?

          raise(
            ShellCommandError,
            "Error code #{exit_code} returned by command \"#{context.command_args.join}\": #{stderr}"
          )
        end
      end
    end
  end
end