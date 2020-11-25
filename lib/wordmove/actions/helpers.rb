module Wordmove
  module Actions
    module Helpers
      extend ActiveSupport::Concern

      # rubocop:disable Metrics/BlockLength
      class_methods do
        def simulate?(cli_options:)
          cli_options.fetch(:simulate, false)
        end

        # Returns the path to be excluded as per movefile.yml configuration.
        # `remote_options` is always valid for both push and pull actions,
        # because path exclusions are configured only on remote environments
        def paths_to_exclude(remote_options:)
          remote_options.fetch(:exclude, [])
        end

        # Given a path, it will append the `/*` string to it. This is how
        # folder content - thus not the folder itself - is represented by rsync
        def exclude_dir_contents(path:)
          "#{path}/*"
        end

        def mysql_dump_command(env_db_options:, save_to_path:)
          command = ['mysqldump']

          if env_db_options[:host].present?
            command << "--host=#{Shellwords.escape(env_db_options[:host])}"
          end

          if env_db_options[:port].present?
            command << "--port=#{Shellwords.escape(env_db_options[:port])}"
          end

          if env_db_options[:user].present?
            command << "--user=#{Shellwords.escape(env_db_options[:user])}"
          end

          if env_db_options[:password].present?
            command << "--password=#{Shellwords.escape(env_db_options[:password])}"
          end

          command << "--result-file=\"#{save_to_path}\""

          if env_db_options[:mysqldump_options].present?
            command << Shellwords.split(env_db_options[:mysqldump_options])
          end

          command << Shellwords.escape(env_db_options[:name])

          command.join(' ')
        end

        def mysql_import_command(dump_path:, env_db_options:)
          command = ['mysql']
          %i[host port user].each do |option|
            if env_db_options[option].present?
              command << "--#{option}=#{Shellwords.escape(env_db_options[option])}"
            end
          end
          if env_db_options[:password].present?
            command << "--password=#{Shellwords.escape(env_db_options[:password])}"
          end
          command << "--database=#{Shellwords.escape(env_db_options[:name])}"
          if env_db_options[:mysql_options].present?
            command << Shellwords.split(env_db_options[:mysql_options])
          end
          command << "--execute=\"SET autocommit=0;SOURCE #{dump_path};COMMIT\""
          command.join(' ')
        end

        def compress_command(file_path:)
          command = ['nice']
          command << '-n'
          command << '0'
          command << 'gzip'
          command << '-9'
          command << '-f'
          command << "\"#{file_path}\""
          command.join(' ')
        end

        def uncompress_command(file_path:)
          command = ['gzip']
          command << '-d'
          command << '-f'
          command << "\"#{file_path}\""
          command.join(' ')
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
