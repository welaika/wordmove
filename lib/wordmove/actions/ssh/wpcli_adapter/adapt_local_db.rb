module Wordmove
  module Actions
    module Ssh
      module WpcliAdapter
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

          executed do |context| # rubocop:disable Metrics/BlockLength
            context.logger.task_step true, 'Adapt URL and paths in DB'

            unless wp_in_path?
              raise UnmetPeerDependencyError, 'WP-CLI is not installed or not in your $PATH'
            end

            next context if simulate?(cli_options: context.cli_options)

            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: mysql_dump_command(
                env_db_options: context.local_options[:database],
                save_to_path: context.db_paths.local.path
              )
            )

            if !context.cli_options[:no_adapt]
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
            else
              context.logger.warn 'Skipping DB adapt'
            end

            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: mysql_dump_command(
                env_db_options: context.local_options[:database],
                save_to_path: context.db_paths.local.adapted_path
              )
            )

            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: compress_command(file_path: context.db_paths.local.adapted_path)
            )

            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: mysql_import_command(
                dump_path: context.db_paths.local.path,
                env_db_options: context.local_options[:database]
              )
            )
          end
        end
      end
    end
  end
end
