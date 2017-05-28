module Wordmove
  module Deployer
    class SshWpcliSqlAdapter < SSH
      def push_db
        super

        # Backup remote db
        download_remote_db(local_gzipped_backup_path)

        # Temporary backup local db
        save_local_db(local_dump_path)

        # search and replace some strings in local db
        run wpcli_search_replace(local_options, remote_options, :vhost)
        run wpcli_search_replace(local_options, remote_options, :wordpress_path)

        # dump adapted database
        local_search_replace_dump_path = local_wp_content_dir.path("search_replace_dump.sql")
        local_gzipped_search_replace_dump_path = local_search_replace_dump_path + '.gz'
        save_local_db(local_search_replace_dump_path)

        # push updated local db to remote db
        run compress_command(local_search_replace_dump_path)
        import_remote_dump(local_gzipped_search_replace_dump_path)
        local_delete(local_gzipped_search_replace_dump_path)

        # restore original local db
        run mysql_import_command(local_dump_path, local_options[:database])
        local_delete(local_dump_path)
      end

      def pull_db
        super

        local_dump_path = local_wp_content_dir.path("dump.sql")
        local_gzipped_dump_path = local_dump_path + '.gz'
        local_backup_path = local_wp_content_dir.path("local-backup-#{Time.now.to_i}.sql")

        # Backup and compress local db
        save_local_db(local_backup_path)
        run compress_command(local_backup_path)

        # Download, uncompress and import remote db
        download_remote_db(local_gzipped_dump_path)
        run uncompress_command(local_gzipped_dump_path)
        run mysql_import_command(local_dump_path, local_options[:database])

        # Adapt local db
        run wpcli_search_replace(remote_options, local_options, :vhost)
        run wpcli_search_replace(remote_options, local_options, :wordpress_path)

        local_delete(local_dump_path)
      end

      def wpcli_search_replace(local, remote, config_key)
        return if options[:no_adapt]

        logger.task_step true, "adapt dump for #{config_key}"
        WpcliSqlAdapter.new(local, remote, config_key).command unless simulate?
      end
    end
  end
end
