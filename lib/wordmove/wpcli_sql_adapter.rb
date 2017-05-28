module Wordmove
  class WpcliSqlAdapter
    attr_accessor :sql_content
    attr_reader :from, :to

    def initialize(source_config, dest_config, config_key)
      @from = source_config[config_key]
      @to = dest_config[config_key]
    end

    def command
      unless system('which wp > /dev/null 2>&1')
        raise UnmetPeerDependencyError, "WP-CLI is not installed or not in your $PATH"
      end

      "wp search-replace #{from} #{to} --quiet --skip-columns=guid"
    end
  end
end
