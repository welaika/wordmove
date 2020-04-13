module Wordmove
  module Actions
    class GetFile
      extend LightService::Action
      expects :photocopier
      expects :logger
      expects :command_args

      executed do |context|
        command = 'get'

        context.logger.task_step false, "#{command}: #{context.command_args.join(' ')}"
        context.photocopier.send(command, *context.command_args)
      end
    end
  end
end
