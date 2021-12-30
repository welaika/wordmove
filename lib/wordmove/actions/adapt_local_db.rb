module Wordmove
  module Actions
    #
    # Adapt the local DB for the remote destination.
    # "To adapt" in Wordmove jargon means to transform URLs strings into the database. This action
    # will substitute local URLs with remote ones, in order to make the DB to work correctly once
    # pushed to the remote wordpress installation.
    #
    class AdaptLocalDb
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      include Wordmove::Wpcli

      expects :local_options,
              :remote_options,
              :cli_options,
              :logger,
              :photocopier,
              :db_paths

      # @!method execute
      # @param local_options [Hash] Local host options fetched from
      #        movefile (with symbolized keys)
      # @param remote_options [Hash] Remote host options fetched from
      #        movefile (with symbolized keys)
      # @param cli_options [Hash] Command line options
      # @param logger [Wordmove::Logger]
      # @param photocopier [Photocopier::SSH|Photocopier::FTP]
      # @param db_paths [BbPathsConfig] Configuration object for database
      # @!scope class
      # @return [LightService::Context] Action's context
      executed do |context| # rubocop:disable Metrics/BlockLength
        context.logger.task 'Adapt local DB'

        unless wp_in_path?
          raise UnmetPeerDependencyError, 'WP-CLI is not installed or not in your $PATH'
        end

        next context if simulate?(cli_options: context.cli_options)

        result = Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,
          logger: context.logger,
          command: mysql_dump_command(
            env_db_options: context.local_options[:database],
            save_to_path: context.db_paths.local.path
          )
        )
        context.fail_and_return!(result.message) if result.failure?

        if context.cli_options[:no_adapt]
          context.logger.warn 'Skipping DB adapt'
        else
          result = Wordmove::Actions::RunLocalCommand.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            command: wpcli_search_replace_command(context, :vhost)
          )
          context.fail_and_return!(result.message) if result.failure?

          result = Wordmove::Actions::RunLocalCommand.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            command: wpcli_search_replace_command(context, :wordpress_path)
          )
          context.fail_and_return!(result.message) if result.failure?
        end

        result = Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,

          logger: context.logger,
          command: mysql_dump_command(
            env_db_options: context.local_options[:database],
            save_to_path: context.db_paths.local.adapted_path
          )
        )
        context.fail_and_return!(result.message) if result.failure?

        if context.photocopier.is_a? Photocopier::SSH
          result = Wordmove::Actions::RunLocalCommand.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            command: compress_command(file_path: context.db_paths.local.adapted_path)
          )
          context.fail_and_return!(result.message) if result.failure?
        end

        result = Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,
          logger: context.logger,
          command: mysql_import_command(
            dump_path: context.db_paths.local.path,
            env_db_options: context.local_options[:database]
          )
        )
        context.fail_and_return!(result.message) if result.failure?
      end
    end
  end
end
