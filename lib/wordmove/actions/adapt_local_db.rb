module Wordmove
  module Actions
    #
    # Adapt the local DB for the remote destination.
    # "To adapt" in Wordmove jargon means to transform URLs strings into the database. This action
    # will substitute local URLs with remote ones, in order to make the DB to work correctly once
    # pushed to the remote wordpress installation.
    #
    class AdaptLocalDb
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      include Wordmove::WpcliHelpers

      expects :local_options,
              :remote_options,
              :cli_options,
              :logger,
              :photocopier,
              :db_paths

      # @!method execute
      # @param local_options [Hash] Local host options fetched from
      #        movefile (with symbolized keys)
      # @param remote_options [Hash] Remote host options fetched from
      #        movefile (with symbolized keys)
      # @param cli_options [Hash] Command line options
      # @param logger [Wordmove::Logger]
      # @param photocopier [Photocopier::SSH|Photocopier::FTP]
      # @param db_paths [BbPathsConfig] Configuration object for database
      # @!scope class
      # @return [LightService::Context] Action's context
      executed do |context| # rubocop:disable Metrics/BlockLength
        context.logger.task 'Adapt local DB'

        unless wp_in_path?
          raise UnmetPeerDependencyError, 'WP-CLI is not installed or not in your $PATH'
        end

        next context if simulate?(cli_options: context.cli_options)

        context.logger.task_step true, dump_command(context)
        begin
          system(dump_command(context), exception: true)
        rescue RuntimeError, SystemExit => e
          context.fail_and_return!("Local command status reports an error: #{e.message}")
        end

        if context.cli_options[:no_adapt]
          context.logger.warn 'Skipping DB adapt'
        else
          %i[vhost wordpress_path].each do |key|
            command = search_replace_command(context, key)
            context.logger.task_step true, command

            begin
              system(command, exception: true)
            rescue RuntimeError, SystemExit => e
              context.fail_and_return!("Local command status reports an error: #{e.message}")
            end
          end
        end

        context.logger.task_step true, dump_adapted_command(context)
        begin
          system(dump_adapted_command(context), exception: true)
        rescue RuntimeError, SystemExit => e
          context.fail_and_return!("Local command status reports an error: #{e.message}")
        end

        if context.photocopier.is_a? Photocopier::SSH
          context.logger.task_step true, compress_command(context)
          begin
            system(compress_command(context), exception: true)
          rescue RuntimeError, SystemExit => e
            context.fail_and_return!("Local command status reports an error: #{e.message}")
          end
        end

        context.logger.task_step true, import_original_db_command(context)
        begin
          system(import_original_db_command(context), exception: true)
        rescue RuntimeError, SystemExit => e
          context.fail_and_return!("Local command status reports an error: #{e.message}")
        end
      end

      def self.dump_command(context)
        "wp db export #{context.db_paths.local.path} --allow-root --quiet " \
          "--path=#{wpcli_config_path(context)}"
      end

      def self.dump_adapted_command(context)
        "wp db export #{context.db_paths.local.adapted_path} --allow-root --quiet " \
          "--path=#{wpcli_config_path(context)}"
      end

      def self.import_original_db_command(context)
        "wp db import #{context.db_paths.local.path} --allow-root --quiet " \
          "--path=#{wpcli_config_path(context)}"
      end

      def self.compress_command(context)
        command = ['nice']
        command << '-n'
        command << '0'
        command << 'gzip'
        command << '-9'
        command << '-f'
        command << "\"#{context.db_paths.local.adapted_path}\""
        command.join(' ')
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
          '"\A' + context.dig(:local_options, config_key) + '\Z"', # rubocop:disable Style/StringConcatenation
          '"' + context.dig(:remote_options, config_key) + '"', # rubocop:disable Style/StringConcatenation
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
