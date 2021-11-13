module Wordmove
  module Actions
    # Delete a local file situated at the given path.
    # Command won't be run if +--simulate+ flag is present on CLI.
    # @note This action is *not* meant to be organized, but as a standalone one.
    class DeleteLocalFile
      extend LightService::Action
      include Wordmove::Actions::Helpers

      expects :file_path,
              :logger,
              :cli_options

      # @!method execute
      #   @param file_path [String]
      #   @param logger [Wordmove::Logger]
      #   @param cli_options [Hash] Command line options (with symbolized keys)
      #   @return [LightService::Context] Action's context
      executed do |context|
        context.logger.task_step true, "delete: '#{context.file_path}'"

        next context if simulate?(cli_options: context.cli_options)

        unless File.exist?(context.file_path)
          context.logger.warn "File #{context.file_path} does not exist. Nothing done."
          next context
        end

        File.delete(context.file_path)
      end
    end
  end
end
