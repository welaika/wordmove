module Wordmove
  class SqlAdapter
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

    def adapt!
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
      length_delta = source_field.length - dest_field.length

      sql_content.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
      sql_content.encode!('UTF-8', 'UTF-16')

      sql_content.gsub!(/s:(\d+):([\\]*['"])(.*?)\2;/) do |match|
        length = $1.to_i
        delimiter = $2
        string = $3

        string.gsub!(/#{Regexp.escape(source_field)}/) do |match|
          length -= length_delta
          dest_field
        end

        %(s:#{length}:#{delimiter}#{string}#{delimiter};)
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
