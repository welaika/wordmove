module Wordmove
  module Actions
    module Ftp
      module Helpers
        extend ActiveSupport::Concern

        class_methods do # rubocop:disable Metrics/BlockLength
          def ftp_options(remote_options:)
            remote_options[:ftp]
          end

          def escape_php(string:)
            return '' unless string

            # replaces \ with \\
            # replaces ' with \'
            string.gsub('\\', '\\\\\\').gsub(/'/, '\\\\\'')
          end

          def generate_dump_script(db:, password:)
            template = ERB.new File.read(File.join(File.dirname(__FILE__), '../assets/dump.php.erb'))
            template.result(binding)
          end

          def generate_import_script(db:, password:)
            template = ERB.new File.read(File.join(File.dirname(__FILE__), '../assets/import.php.erb'))
            template.result(binding)
          end

          # To turn into an action
          def download_remote_db(local_dump_path:)
            remote_dump_script = remote_wp_content_dir.path('dump.php')
            # generate a secure one-time password
            one_time_password = SecureRandom.hex(40)
            # generate dump script
            dump_script = generate_dump_script(remote_options[:database], one_time_password)
            # upload the dump script
            remote_put(dump_script, remote_dump_script)
            # download the resulting dump (using the password)
            dump_url = "#{remote_wp_content_dir.url('dump.php')}?shared_key=#{one_time_password}"
            download(dump_url, local_dump_path)
            # cleanup remotely
            remote_delete(remote_dump_script)
            remote_delete(remote_wp_content_dir.path('dump.mysql'))
          end

          # To turn into an action
          def import_remote_dump
            temp_path = local_wp_content_dir.path('log.html')
            remote_import_script_path = remote_wp_content_dir.path('import.php')
            # generate a secure one-time password
            one_time_password = SecureRandom.hex(40)
            # generate import script
            import_script = generate_import_script(remote_options[:database], one_time_password)
            # upload import script
            remote_put(import_script, remote_import_script_path)
            # run import script
            import_url = [
              remote_wp_content_dir.url('import.php').to_s,
              "?shared_key=#{one_time_password}",
              '&start=1&foffset=0&totalqueries=0&fn=dump.sql'
            ].join
            download(import_url, temp_path)
            if options[:debug]
              logger.debug "Operation log located at: #{temp_path}"
            else
              local_delete(temp_path)
            end
            # remove script remotely
            remote_delete(remote_import_script_path)
          end

          def adapt_sql(save_to_path:, local:, remote:)
            return if options[:no_adapt]

            logger.task_step true, 'Adapt dump'
            SqlAdapter::Default.new(save_to_path, local, remote).adapt! unless simulate?
          end
        end
      end
    end
  end
end
