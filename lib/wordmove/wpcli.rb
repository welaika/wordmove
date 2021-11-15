module Wordmove
  module Wpcli
    extend ActiveSupport::Concern

    included do
      private_class_method :load_from_wpcli, :load_from_yml
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      def wp_in_path?
        system('which wp > /dev/null 2>&1')
      end

      def wpcli_search_replace_command(context, config_key)
        [
          'wp search-replace',
          "--path=#{wpcli_config_path(context)}",
          context.remote_options[config_key],
          context.local_options[config_key],
          '--quiet',
          '--skip-columns=guid',
          '--all-tables',
          '--allow-root'
        ].join(' ')
      end

      def wpcli_config_path(context)
        load_from_yml(context) || load_from_wpcli || context.local_options[:wordpress_path]
      end

      def load_from_yml(context)
        yml_path = File.join(context.local_options[:wordpress_path], 'wp-cli.yml')

        return unless File.exist?(yml_path)

        YAML.load_file(yml_path).with_indifferent_access['path']
      end

      def load_from_wpcli
        wpcli_config = JSON.parse(`wp cli param-dump --with-values`, symbolize_names: true)
        wpcli_config.dig(:path, :current)
      end
    end
  end
end
