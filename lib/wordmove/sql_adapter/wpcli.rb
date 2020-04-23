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

        [
          "wp",
          "search-replace",
          cli_config_exists? ? "" : "--path=#{local_path}",
          from,
          to,
          "--quiet",
          "--skip-columns=guid",
          "--all-tables",
          "--allow-root"
        ].join(' ')
      end

      private

      def wp_in_path?
        system('which wp > /dev/null 2>&1')
      end

      def cli_config_exists?
        cli_config_path = File.join(local_path, "wp-cli.yml")
        File.exist?(cli_config_path)
      end
    end
  end
end
