module Wordmove
  module Actions
    class RunLocalCommand
      extend LightService::Action
      include Wordmove::Actions::Helpers
      expects :command,
              :cli_options,
              :logger

      executed do |context|
        context.logger.task_step true, context.command

        next context if simulate?(cli_options: context.cli_options)

        system(context.command)

        raise ShellCommandError, "Return code reports an error" unless $CHILD_STATUS.success?
      end
    end
  end
end
