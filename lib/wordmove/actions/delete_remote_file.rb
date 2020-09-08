module Wordmove
  module Actions
    class DeleteRemoteFile
      extend LightService::Action

      expects :photocopier,
              :logger,
              :command_args

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
