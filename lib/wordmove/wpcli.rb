module Wordmove
  # This class is a sort of mini-wrapper around the wp-cli executable.
  # It's responsible to run or produce wp-cli commands.
  module Wpcli
    extend ActiveSupport::Concern

    included do
      private_class_method :load_from_wpcli, :load_from_yml
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      # Checks if `wp` command is in your shell `$PATH`
      #
      # @return [Boolean]
      # @!scope class
      def wp_in_path?
        system('which wp > /dev/null 2>&1')
      end

      # Compose and returns the search-replace command. It's intended to be
      # used from a +LightService::Action+
      #
      # @param context [LightService::Context] The context of an action
      # @param config_key [:vhost, :wordpress_path] Determines what will be replaced in DB
      # @return [String]
      # @!scope class
      def wpcli_search_replace_command(context, config_key)
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

      # Returns the wordpress path from wp-cli (with precedence) or from movefile
      #
      # It's intended to be used from a +LightService::Action+
      #
      # @param context [LightService::Context] The context of an action
      # @return [String]
      # @!scope class
      def wpcli_config_path(context)
        load_from_yml(context) || load_from_wpcli || context.dig(:local_options, :wordpress_path)
      end

      # If wordpress installation brings a `wp-cli.yml` file in its root folder,
      # reads it and returns the `path` yaml key configured there
      #
      # @return [String, nil] The `path` configuration or `nil`
      # @!scope class
      # @!visibility private
      def load_from_yml(context)
        yml_path = File.join(context.dig(:local_options, :wordpress_path), 'wp-cli.yml')

        return unless File.exist?(yml_path)

        YAML.load_file(yml_path).with_indifferent_access['path']
      end

      # Returns the wordpress path as per wp-cli configuration.
      # A possible scenario is that the used wpcli command could return an empty
      # string: we thus rescue parse errors in order to ignore this config source
      #
      # @return [String, nil] The wordpress path as per wp-cli configuration or nil
      # @!scope class
      # @!visibility private
      def load_from_wpcli
        wpcli_config = JSON.parse(
          `wp cli param-dump --with-values --allow-root`,
          symbolize_names: true
        )
        wpcli_config.dig(:path, :current)
      rescue JSON::ParserError => _e
        nil
      end
    end
  end
end
