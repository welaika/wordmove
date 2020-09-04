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
        result = context.photocopier.send(command, *context.command_args)

        next context if result == true

        context.fail! "Failed to upload file: #{context.command_args.first}"
      end
    end
  end
end
