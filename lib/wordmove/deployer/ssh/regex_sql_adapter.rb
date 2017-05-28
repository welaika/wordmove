module Wordmove
  module Deployer
    module Ssh
      class RegexSqlAdapter < SSH
        private

        def backup_remote_db!
          download_remote_db(local_gzipped_backup_path)
        end

        def adapt_local_db!
          save_local_db(local_dump_path)
          adapt_sql(local_dump_path, local_options, remote_options)
          run compress_command(local_dump_path)
          import_remote_dump(local_gzipped_dump_path)
        end

        def after_push_cleanup!
          local_delete(local_gzipped_dump_path)
        end

        def backup_local_db!
          save_local_db(local_backup_path)
          run compress_command(local_backup_path)
        end

        def adapt_remote_db!
          download_remote_db(local_gzipped_dump_path)
          run uncompress_command(local_gzipped_dump_path)
          adapt_sql(local_dump_path, remote_options, local_options)
          run mysql_import_command(local_dump_path, local_options[:database])
        end

        def after_pull_cleanup!
          local_delete(local_dump_path)
        end

        def adapt_sql(save_to_path, local, remote)
          return if options[:no_adapt]

          logger.task_step true, "Adapt dump"
          DefaultSqlAdapter.new(save_to_path, local, remote).adapt! unless simulate?
        end
      end
    end
  end
end
