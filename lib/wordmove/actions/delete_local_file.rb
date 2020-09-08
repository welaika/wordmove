module Wordmove
  module Actions
    class DeleteLocalFile
      extend LightService::Action
      include Wordmove::Actions::Helpers

      expects :file_path,
              :logger,
              :cli_options

      executed do |context|
        context.logger.task_step true, "delete: '#{context.file_path}'"

        next context if simulate?(cli_options: context.cli_options)

        unless File.exist?(context.file_path)
          context.logger.warning 'File does not exist'
          next context
        end

        File.delete(context.file_path)
      end
    end
  end
end
