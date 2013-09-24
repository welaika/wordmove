require 'ostruct'
require 'wordmove/wordpress_directory'

module Wordmove
  module Generators
    module MovefileAdapter
      def wordpress_path
        File.expand_path(Dir.pwd)
      end

      def database
        DBConfigReader.config
      end
    end

    class DBConfigReader
      def self.config
        new.config
      end

      def config
        OpenStruct.new(database_config)
      end

      def database_config
        if wp_config_exists?
          WordpressDBConfig.config
        else
          DefaultDBConfig.config
        end
      end

      def wp_config_exists?
        File.exists?(WordpressDirectory.default_path_for(:wp_config))
      end
    end

    class DefaultDBConfig
      def self.config
        {
          name: "database_name",
          user: "user",
          password: "password",
          host: "127.0.0.1"
        }
      end
    end

    class WordpressDBConfig
      def self.config
        new.config
      end

      def wp_config
        @wp_config ||= File.open(WordpressDirectory.default_path_for(:wp_config)).read
      end

      def wp_definitions
        {
          name: 'DB_NAME',
          user: 'DB_USER',
          password: 'DB_PASSWORD',
          host: 'DB_HOST'
        }
      end

      def wp_definition_regex(definition)
        /['"]#{definition}['"],\s*["'](?<value>.*)['"]/
      end

      def defaults
        DefaultDBConfig.config.clone
      end

      def config
        wp_definitions.each_with_object(defaults) do |(key, definition), result|
          wp_config.match(wp_definition_regex(definition)) do |match|
            result[key] = match[:value]
          end
        end
      end

    end
  end
end

