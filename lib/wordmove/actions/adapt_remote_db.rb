module Wordmove
  module Actions
    #
    # Adapt the remote DB for the local destination.
    # "To adapt" in Wordmove jargon means to transform URLs strings into the database. This action
    # will substitute remote URLs with local ones, in order to make the DB to work correctly once
    # pulled to the local wordpress installation.
    #
    # @note This action is not responsible to download the remote DB nor to backup any DB at all.
    #       It expects to find a dump of the remote DB into +context.db_paths.local.gzipped_path+
    #       (SSH) or +context.db_paths.local.path+ (FTP), otherwise it will fail and stop the
    #       procedure.
    #
    class AdaptRemoteDb
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      include Wordmove::Wpcli

      expects :local_options,
              :cli_options,
              :logger,
              :db_paths

      # @!method execute
      # @param local_options [Hash] Local host options fetched from
      #        movefile (with symbolized keys)
      # @param cli_options [Hash] Command line options
      # @param logger [Wordmove::Logger]
      # @param db_paths [BbPathsConfig] Configuration object for database
      # @!scope class
      # @return [LightService::Context] Action's context
      executed do |context| # rubocop:disable Metrics/BlockLength
        context.logger.task 'Adapt remote DB'

        unless wp_in_path?
          raise UnmetPeerDependencyError, 'WP-CLI is not installed or not in your $PATH'
        end

        next context if simulate?(cli_options: context.cli_options)

        if File.exist?(context.db_paths.local.gzipped_path)
          Wordmove::Actions::RunLocalCommand.execute(
            cli_options: context.cli_options,
            logger: context.logger,
            command: uncompress_command(file_path: context.db_paths.local.gzipped_path)
          )
        end

        unless File.exist?(context.db_paths.local.path)
          context.fail_and_return!(
            "Cannot find the dump file to adapt in #{context.db_paths.local.path}"
          )
        end

        Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,
          logger: context.logger,
          command: mysql_import_command(
            dump_path: context.db_paths.local.path,
            env_db_options: context.local_options[:database]
          )
        )

        if context.cli_options[:no_adapt]
          context.logger.warn 'Skipping DB adapt'
          next context
        end

        Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,
          logger: context.logger,
          command: wpcli_search_replace_command(context, :vhost)
        )

        Wordmove::Actions::RunLocalCommand.execute(
          cli_options: context.cli_options,
          logger: context.logger,
          command: wpcli_search_replace_command(context, :wordpress_path)
        )
      end
    end
  end
end
