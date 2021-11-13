module Wordmove
  module Actions
    module Ssh
      module WpcliAdapter
        class AdaptRemoteDb
          extend ::LightService::Action
          include Wordmove::Actions::Helpers

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

            Wordmove::Actions::Ssh::DownloadRemoteDb.execute(context)

            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: uncompress_command(file_path: context.db_paths.local.gzipped_path)
            )

            Wordmove::Actions::RunLocalCommand.execute(
              cli_options: context.cli_options,
              logger: context.logger,
              command: mysql_import_command(
                dump_path: context.db_paths.local.path,
                env_db_options: context.local_options[:database]
              )
            )

            next context if context.cli_options[:no_adapt]

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

          # This should be extracted into a concern
          def self.wpcli_search_replace_command(context, config_key)
            wordpress_path = context.local_options[:wordpress_path]

            [
              'wp search-replace',
              "--path=#{wordpress_path}",
              context.remote_options[config_key],
              context.local_options[config_key],
              '--quiet',
              '--skip-columns=guid',
              '--all-tables',
              '--allow-root'
            ].join(' ')
          end

          # This should be extracted into a concern
          def self.wp_in_path?
            system('which wp > /dev/null 2>&1')
          end
        end
      end
    end
  end
end
