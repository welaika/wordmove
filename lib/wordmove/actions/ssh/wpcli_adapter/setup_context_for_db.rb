module Wordmove
  module Actions
    module Ssh
      module WpcliAdapter
        class SetupContextForDb
          extend ::LightService::Action
          include Wordmove::Actions::Helpers
          include WordpressDirectory::LocalHelperMethods
          include WordpressDirectory::RemoteHelperMethods

          expects :cli_options,
                  :local_options,
                  :remote_options,
                  :logger,
                  :photocopier,
                  :movefile,
                  :database_task
          promises :db_paths

          executed do |context|
            context.logger.task 'Pushing Database'

            next context if simulate?(cli_options: context.cli_options)

            content_dir = local_wp_content_dir(local_options: context.local_options)

            DbPathsConfig.local.path = content_dir.path('dump.sql')
            DbPathsConfig.local.gzipped_path = DbPathsConfig.local.path + '.gz'
            DbPathsConfig.remote.path = remote_wp_content_dir(
              remote_options: context.remote_options
            ).path('dump.sql')
            DbPathsConfig.remote.gzipped_path = DbPathsConfig.remote.path + '.gz'
            DbPathsConfig.local.adapted_path = content_dir.path('search_replace_dump.sql')
            DbPathsConfig.local.gzipped_adapted_path = DbPathsConfig.local.adapted_path + '.gz'
            DbPathsConfig.backup.local.path = content_dir.path("local-backup-#{Time.now.to_i}.sql")
            DbPathsConfig.backup.local.gzipped_path = DbPathsConfig.backup.local.path + '.gz'
            DbPathsConfig.backup.remote.path =
              content_dir.path("#{context.movefile.environment}-backup-#{Time.now.to_i}.sql")
            DbPathsConfig.backup.remote.gzipped_path = DbPathsConfig.backup.remote.path + '.gz'

            context.db_paths = DbPathsConfig

            context.skip_remaining! if context.database_task == false
          end
        end
      end
    end
  end
end
