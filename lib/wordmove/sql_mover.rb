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
      replace_field!(:vhost)
    end

    def replace_wordpress_path!
      replace_field!(:wordpress_path)
    end

    def replace_field!(field_sym)
      source_field = source_config[field_sym]
      dest_field = dest_config[field_sym]
      if source_field && dest_field
        serialized_replace!(source_field, dest_field)
        simple_replace!(source_field, dest_field)
      end
    end

    def serialized_replace!(source_field, dest_field)
      length_delta = source_field.length - dest_field.length

      sql_content.gsub!(/s:(\d+):"#{Regexp.escape(source_field)}/) do |match|
        source_length = $1.to_i
        dest_length = source_length - length_delta
        "s:#{dest_length}:\"#{dest_field}"
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
