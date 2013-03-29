module Wordmove

  class SqlMover

    attr_accessor :sql_content
    attr_reader :sql_path, :source_config, :dest_config

    def initialize(sql_path, source_config, dest_config)
      @sql_path = sql_path
      @source_config = source_config
      @dest_config = dest_config
    end

    def sql_content
      @sql_content ||= File.open(sql_path).read
    end

    def move!
      replace_vhost!
      replace_wordpress_path!
      write_sql!
    end

    def replace_vhost!
      source_vhost = source_config[:vhost]
      dest_vhost = dest_config[:vhost]
      replace_field!(source_vhost, dest_vhost)
    end

    def replace_wordpress_path!
      source_path = source_config[:wordpress_absolute_path] || source_config[:wordpress_path]
      dest_path = dest_config[:wordpress_absolute_path] || dest_config[:wordpress_path]
      replace_field!(source_path, dest_path)
    end

    def replace_field!(source_field, dest_field)
      if source_field && dest_field
        serialized_replace!(source_field, dest_field)
        simple_replace!(source_field, dest_field)
      end
    end

    def serialized_replace!(source_field, dest_field)
      sql_content.gsub!(/s:(?:\d+):(\\*['"])(.*?)\1;/) do |match|
        delimiter, string = $1, $2
        string.gsub!(/#{Regexp.escape(source_field)}/, dest_field)
        %(s:#{string.length}:#{delimiter}#{string}#{delimiter};)
      end
    end

    def simple_replace!(source_field, dest_field)
      sql_content.gsub!(source_field, dest_field)
    end

    def write_sql!
      File.open(sql_path, 'w') {|f| f.write(sql_content) }
    end
  end
end
