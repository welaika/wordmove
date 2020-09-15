module Wordmove
  module Actions
    module Ssh
      class RunRemoteCommand
        extend LightService::Action
        include Wordmove::Actions::Helpers

        expects :photocopier,
                :logger,
                :cli_options,
                :command

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
