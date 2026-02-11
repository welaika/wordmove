module Wordmove
  module Deployer
    module Ssh
      class WpcliSqlAdapter < SSH
        def backup_remote_db!
          download_remote_db(local_gzipped_backup_path)
        end

        def adapt_local_db!
          save_local_db(local_dump_path)
          run wpcli_search_replace(local_options, remote_options, :vhost)
          run wpcli_search_replace(local_options, remote_options, :wordpress_path)

          local_search_replace_dump_path = local_wp_content_dir.path("search_replace_dump.sql")
          local_gzipped_search_replace_dump_path = "#{local_search_replace_dump_path}.gz"

          save_local_db(local_search_replace_dump_path)
          run compress_command(local_search_replace_dump_path)
          import_remote_dump(local_gzipped_search_replace_dump_path)
          local_delete(local_gzipped_search_replace_dump_path)
          run mysql_import_command(local_dump_path, local_options[:database])
        end

        def after_push_cleanup!
          local_delete(local_dump_path)
        end

        def backup_local_db!
          save_local_db(local_backup_path)
          run compress_command(local_backup_path)
        end

        def adapt_remote_db!
          download_remote_db(local_gzipped_dump_path)
          run uncompress_command(local_gzipped_dump_path)
          run mysql_import_command(local_dump_path, local_options[:database])
          run wpcli_search_replace(remote_options, local_options, :vhost)
          run wpcli_search_replace(remote_options, local_options, :wordpress_path)
        end

        def after_pull_cleanup!
          local_delete(local_dump_path)
        end

        def wpcli_search_replace(local, remote, config_key)
          return if options[:no_adapt]

          logger.task_step true, "adapt dump for #{config_key}"
          path = local_options[:wordpress_path]
          SqlAdapter::Wpcli.new(local, remote, config_key, path).command unless simulate?
        end
      end
    end
  end
end
