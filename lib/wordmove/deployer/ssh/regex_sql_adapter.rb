module Wordmove
  module Deployer
    module Ssh
      class RegexSqlAdapter < SSH
        def push_db
          super

          local_dump_path = local_wp_content_dir.path("dump.sql")
          local_gzipped_dump_path = local_dump_path + '.gz'
          local_gzipped_backup_path = local_wp_content_dir
                                      .path("#{environment}-backup-#{Time.now.to_i}.sql.gz")

          download_remote_db(local_gzipped_backup_path)

          save_local_db(local_dump_path)
          adapt_sql(local_dump_path, local_options, remote_options)
          run compress_command(local_dump_path)
          import_remote_dump(local_gzipped_dump_path)
          local_delete(local_gzipped_dump_path)
        end

        def pull_db
          super

          local_dump_path = local_wp_content_dir.path("dump.sql")
          local_gzipped_dump_path = local_dump_path + '.gz'
          local_backup_path = local_wp_content_dir.path("local-backup-#{Time.now.to_i}.sql")

          save_local_db(local_backup_path)
          run compress_command(local_backup_path)

          download_remote_db(local_gzipped_dump_path)
          run uncompress_command(local_gzipped_dump_path)
          adapt_sql(local_dump_path, remote_options, local_options)
          run mysql_import_command(local_dump_path, local_options[:database])
          local_delete(local_dump_path)
        end

      end
    end
  end
end
