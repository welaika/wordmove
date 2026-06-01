module Wordmove
  module Actions
    #
    # Adapt the remote DB for the local destination.
    # "To adapt" in Wordmove jargon means to transform URLs strings into the database. This action
    # will substitute remote URLs with local ones, in order to make the DB to work correctly once
    # pulled to the local wordpress installation.
    #
    # @note This action is not responsible to download the remote DB nor to backup any DB at all.
    #       It expects to find a dump of the remote DB into +context.db_paths.local.gzipped_path+
    #       (SSH) or +context.db_paths.local.path+ (FTP), otherwise it will fail and stop the
    #       procedure.
    #
    class AdaptRemoteDb
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      include Wordmove::WpcliHelpers

      expects :local_options,
              :cli_options,
              :logger,
              :db_paths

      # @!method execute
      # @param local_options [Hash] Local host options fetched from
      #        movefile (with symbolized keys)
      # @param cli_options [Hash] Command line options
      # @param logger [Wordmove::Logger]
      # @param db_paths [BbPathsConfig] Configuration object for database
      # @!scope class
      # @return [LightService::Context] Action's context
      executed do |context| # rubocop:disable Metrics/BlockLength
        context.logger.task 'Adapt remote DB'

        unless wp_in_path?
          raise UnmetPeerDependencyError, 'WP-CLI is not installed or not in your $PATH'
        end

        next context if simulate?(cli_options: context.cli_options)

        if File.exist?(context.db_paths.local.gzipped_path)
          context.logger.task_step true, uncompress_command(context)
          begin
            system(uncompress_command(context), exception: true)
          rescue RuntimeError, SystemExit => e
            context.fail_and_return!("Local command status reports an error: #{e.message}")
          end
        end

        unless File.exist?(context.db_paths.local.path)
          context.fail_and_return!(
            "Cannot find the dump file to adapt in #{context.db_paths.local.path}"
          )
        end

        context.logger.task_step true, import_db_command(context)
        begin
          system(import_db_command(context), exception: true)
        rescue RuntimeError, SystemExit => e
          context.fail_and_return!("Local command status reports an error: #{e.message}")
        end

        if context.cli_options[:no_adapt]
          context.logger.warn 'Skipping DB adapt'
          next context
        end

        %i[vhost wordpress_path].each do |key|
          command = search_replace_command(context, key)
          context.logger.task_step true, command
          begin
            system(command, exception: true)
          rescue RuntimeError, SystemExit => e
            context.fail_and_return!("Local command status reports an error: #{e.message}")
          end
        end

        context.logger.success 'Local DB adapted'
      end

      # Construct the command to deflate a compressed file as a string.
      #
      # @param file_path [String] The path where the file to be deflated is located
      # @return [String] the command
      # @!scope class
      def self.uncompress_command(context)
        command = ['gzip']
        command << '-d'
        command << '-f'
        command << "\"#{context.db_paths.local.gzipped_path}\""
        command.join(' ')
      end

      def self.import_db_command(context)
        "wp db import #{context.db_paths.local.path} --allow-root --quiet " \
          "--path=#{wpcli_config_path(context)}"
      end

      # Compose and returns the search-replace command. It's intended to be
      # used from a +LightService::Action+
      #
      # @param context [LightService::Context] The context of an action
      # @param config_key [:vhost, :wordpress_path] Determines what will be replaced in DB
      # @return [String]
      # @!scope class
      def self.search_replace_command(context, config_key)
        unless %i[vhost wordpress_path].include?(config_key)
          raise ArgumentError, "Unexpected `config_key` #{config_key}.:vhost" \
                               'or :wordpress_path expected'
        end

        [
          'wp search-replace',
          "--path=#{wpcli_config_path(context)}",
          '"\A' + context.dig(:remote_options, config_key) + '\Z"', # rubocop:disable Style/StringConcatenation
          '"' + context.dig(:local_options, config_key) + '"', # rubocop:disable Style/StringConcatenation
          '--regex-delimiter="|"',
          '--regex',
          '--precise',
          '--quiet',
          '--skip-columns=guid',
          '--all-tables',
          '--allow-root'
        ].join(' ')
      end
    end
  end
end
