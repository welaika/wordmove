module Wordmove
  module Actions
    # Delete a remote file
    # @note This action is *not* meant to be organized, but as a standalone one.
    class DeleteRemoteFile
      extend LightService::Action
      include Wordmove::Actions::Helpers

      expects :photocopier,
              :logger,
              :cli_options,
              :remote_file

      # @!method execute
      # @param photocopier [Photocopier]
      # @param logger [Wordmove::Logger]
      # @param cli_options [Hash] Command line options (with symbolized keys)
      # @param remote_file ((String) remote file path)
      # @!scope class
      # @return [LightService::Context] Action's context
      executed do |context|
        command = 'delete'

        context.logger.task_step false, "#{command}: #{context.remote_file}"

        next context if simulate?(cli_options: context.cli_options)

        _stdout, stderr, exit_code = context.photocopier.send(command, context.remote_file)

        next context if exit_code&.zero?

        # When +context.photocopier+ is a +Photocopier::FTP+ instance, +delte+ will always
        # return +nil+; so it's impossible to correctly fail the context when using
        # FTP protocol. The problem is how +Net::FTP+ ruby class behaves.
        # IMO this is an acceptable tradeoff.
        unless exit_code.nil?
          context.fail! "Error code #{exit_code} returned while deleting file "\
                        "#{context.remote_file}: #{stderr}"
        end
      end
    end
  end
end
