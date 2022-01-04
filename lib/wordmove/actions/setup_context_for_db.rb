module Wordmove
  module Actions
    class SetupContextForDb
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      include Wordmove::Actions::Ftp::Helpers
      include WordpressDirectory::LocalHelperMethods
      include WordpressDirectory::RemoteHelperMethods

      expects :cli_options,
              :local_options,
              :remote_options,
              :logger,
              :movefile,
              :database_task
      promises :db_paths

      executed do |context| # rubocop:disable Metrics/BlockLength
        next context if simulate?(cli_options: context.cli_options)

        content_dir = local_wp_content_dir(local_options: context.local_options)

        token = remote_php_scripts_token

        DbPathsConfig.local.path = content_dir.path('dump.sql')
        DbPathsConfig.local.gzipped_path = "#{DbPathsConfig.local.path}.gz"
        DbPathsConfig.remote.path = remote_wp_content_dir(
          remote_options: context.remote_options
        ).path('dump.sql')
        DbPathsConfig.remote.gzipped_path = "#{DbPathsConfig.remote.path}.gz"
        DbPathsConfig.local.adapted_path = content_dir.path('search_replace_dump.sql')
        DbPathsConfig.local.gzipped_adapted_path = "#{DbPathsConfig.local.adapted_path}.gz"
        DbPathsConfig.backup.local.path = content_dir.path("local-backup-#{Time.now.to_i}.sql")
        DbPathsConfig.backup.local.gzipped_path = "#{DbPathsConfig.backup.local.path}.gz"
        DbPathsConfig.backup.remote.path =
          content_dir.path("#{context.movefile.environment}-backup-#{Time.now.to_i}.sql")
        DbPathsConfig.backup.remote.gzipped_path = "#{DbPathsConfig.backup.remote.path}.gz"

        DbPathsConfig.ftp.remote.dump_script_path = remote_wp_content_dir(
          remote_options: context.remote_options
        ).path('dump.php')
        DbPathsConfig.ftp.remote.dumped_path = remote_wp_content_dir(
          remote_options: context.remote_options
        ).path('dump.mysql')
        DbPathsConfig.ftp.remote.dump_script_url = remote_wp_content_dir(
          remote_options: context.remote_options
        ).url('dump.php')
        DbPathsConfig.ftp.remote.import_script_path = remote_wp_content_dir(
          remote_options: context.remote_options
        ).path('import.php')
        DbPathsConfig.ftp.remote.import_script_url = remote_wp_content_dir(
          remote_options: context.remote_options
        ).url('import.php')
        DbPathsConfig.ftp.local.generated_dump_script_path = generate_dump_script(
          remote_db_options: context.remote_options[:database], token:
        )
        DbPathsConfig.ftp.local.generated_import_script_path = generate_import_script(
          remote_db_options: context.remote_options[:database], token:
        )
        DbPathsConfig.ftp.local.temp_path = local_wp_content_dir(
          local_options: context.local_options
        ).path('log.html')
        # I know this is not a path, but it's used to generate
        # a URL to dump the DB, so it's somewhat in context
        DbPathsConfig.ftp.token = token

        context.db_paths = DbPathsConfig
      end
    end
  end
end
