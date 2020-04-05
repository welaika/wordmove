module Wordmove
  module Actions
    # Helpers for +Wordmove::Actions+
    #
    # All helpers methos are class methods; this way we force avoiding the use
    # of persistence. All actions have to be approached more as functional code
    # than OO code. Thus helpers are condidered as functional code too.
    module Helpers
      extend ActiveSupport::Concern

      # rubocop:disable Metrics/BlockLength
      class_methods do
        # Determines if we're running a simulated command. Actually this is a
        # wrapper around command line arguments set by the user.
        #
        # @param cli_options [Hash] Command line options hash (deep symbolized).
        #        Generally you will find this into action's context
        # @return [Boolean]
        def simulate?(cli_options:)
          cli_options.fetch(:simulate, false)
        end

        # Returns the path to be excluded as per movefile.yml configuration.
        # `remote_options` is always valid for both push and pull actions,
        # because path exclusions are configured only on remote environments
        #
        # @param remote_options [Hash] The options hash for the selected remote
        #        remote environment. Generally you will find this into action's context.
        # @return [Array<String>]
        def paths_to_exclude(remote_options:)
          remote_options.fetch(:exclude, [])
        end

        # Given a path, it will append the `/*` string to it. This is how
        # folder content - thus not the folder itself - is represented by rsync.
        # The name of this method is not explicative nor expressive, but we retain
        # it for backward compatibility.
        #
        # @param path [String]
        # @return [String]
        def exclude_dir_contents(path:)
          "#{path}/*"
        end

        # Construct the mysql dump command as a string
        #
        # @param env_db_options [Hash] This hash is defined by the user through movefile.yml
        # @param save_to_path [String] The path where the db dump will be saved
        # @return [String] The full composed mysql command
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

        # Construct the mysql import command as a string
        #
        # @param dump_path [String] The path where the dump to import is located
        # @param env_db_options [Hash] This hash is defined by the user through movefile.yml
        # @return [String] The full composed mysql command
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

        # Construct the command to compress a file as a string. The command will be wrapped
        # as argument to the +nice+ command, in order to lower the process priority and do
        # not lock the system while compressing large files.
        #
        # @param file_path [String] The path where the file to be compressed is located
        # @return [String] the command
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

        # Construct the command to deflate a compressed file as a string.
        #
        # @param file_path [String] The path where the file to be deflated is located
        # @return [String] the command
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
