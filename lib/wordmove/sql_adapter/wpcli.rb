module Wordmove
  module SqlAdapter
    class Wpcli
      attr_accessor :sql_content
      attr_reader :from, :to, :local_path

      def initialize(source_config, dest_config, config_key, local_path)
        @from = source_config[config_key]
        @to = dest_config[config_key]
        @local_path = local_path
      end

      def command
        unless wp_in_path?
          raise UnmetPeerDependencyError, "WP-CLI is not installed or not in your $PATH"
        end

        opts = [
          "--path=#{cli_config_path}",
          from,
          to,
          "--quiet",
          "--skip-columns=guid",
          "--all-tables",
          "--allow-root"
        ]

        "wp search-replace #{opts.join(' ')}"
      end

      private

      def wp_in_path?
        system('which wp > /dev/null 2>&1')
      end

      def cli_config_path
        load_from_yml || load_from_cli || local_path
      end

      def load_from_yml
        cli_config_path = File.join(local_path, "wp-cli.yml")
        return unless File.exist?(cli_config_path)

        YAML.load_file(cli_config_path).with_indifferent_access["path"]
      end

      def load_from_cli
        cli_config = JSON.parse(`wp cli param-dump --with-values`, symbolize_names: true)
        cli_config.dig(:path, :current)
      end
    end
  end
end
