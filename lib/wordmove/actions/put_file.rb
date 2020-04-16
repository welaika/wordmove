module Wordmove
  module Actions
    class PutFile
      extend LightService::Action
      expects :photocopier
      expects :logger
      expects :command_args

      executed do |context|
        command = 'put'

        context.logger.task_step false, "#{command}: #{context.command_args.join(' ')}"
        context.photocopier.send(command, *context.command_args)
      end
    end
  end
end
