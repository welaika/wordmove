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
        result = context.photocopier.send(command, *context.command_args)

        next context if result == true

        context.fail! "Failed to download file: #{context.command_args.first}"
      end
    end
  end
end
