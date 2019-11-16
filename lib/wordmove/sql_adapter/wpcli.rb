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
        unless system('which wp > /dev/null 2>&1')
          raise UnmetPeerDependencyError, "WP-CLI is not installed or not in your $PATH"
        end

        "wp search-replace --path=#{local_path} #{from} #{to} --quiet "\
        "--skip-columns=guid --all-tables --allow-root"
      end
    end
  end
end
