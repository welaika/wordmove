module Wordmove
  # This class is a sort of mini-wrapper around the wp-cli executable.
  # It's responsible to run or produce wp-cli commands.
  module WpcliHelpers
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

      # Returns the wordpress path from wp-cli (with precedence) or from movefile
      #
      # It's intended to be used from a +LightService::Action+, but it also supports
      # to receive a path as argument. If the argument is not a LightService::Context
      # then it will be treated as a path.
      # The path passed as argument should be the wordpress installation path, but it's
      # not strictly mandatory: the method will try to load a wpcli's YAML config
      # from that path, so you can potentially use it with any path
      #
      # @param context [LightService::Context|String] The context of an action or a path as string
      # @return [String]
      # @!scope class
      def wpcli_config_path(context_or_path)
        context = if context_or_path.is_a? LightService::Context
                    context_or_path
                  else
                    # We need to make it quack like a duck in order to be
                    # backward compatible with previous code
                    { local_options: { wordpress_path: context_or_path } }
                  end

        load_from_yml(context) || load_from_wpcli || context.dig(:local_options, :wordpress_path)
      end

      # If wordpress installation brings a `wp-cli.yml` file in its root folder,
      # reads it and returns the `path` yaml key configured there
      #
      # @return [String, nil] The `path` configuration or `nil`
      # @!scope class
      # @!visibility private
      def load_from_yml(context)
        config_path = context.dig(:local_options, :wordpress_path) || '.'
        yml_path = File.join(config_path, 'wp-cli.yml')

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

    def self.get_option(option, config_path:)
      `wp option get #{option} --allow-root --path=#{config_path}`.chomp
    end

    def self.get_config(config, config_path:)
      `wp config get #{config} --allow-root --path=#{config_path}`.chomp
    end
  end
end
