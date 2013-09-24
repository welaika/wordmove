class WordpressDirectory < Struct.new(:type, :options)

  module PATH
    WP_CONTENT = :wp_content
    WP_CONFIG  = :wp_config
    PLUGINS    = :plugins
    THEMES     = :themes
    UPLOADS    = :uploads
    LANGUAGES  = :languages
  end

  DEFAULT_PATHS = {
    PATH::WP_CONTENT => 'wp-content',
    PATH::WP_CONFIG  => 'wp-config.php',
    PATH::PLUGINS    => 'wp-content/plugins',
    PATH::THEMES     => 'wp-content/themes',
    PATH::UPLOADS    => 'wp-content/uploads',
    PATH::LANGUAGES  => 'wp-content/languages'
  }

  def self.default_path_for(sym)
    DEFAULT_PATHS[sym]
  end

  def path(*args)
    File.join(options[:wordpress_path], relative_path(*args))
  end

  def url(*args)
    File.join(options[:vhost], relative_path(*args))
  end

  def relative_path(*args)
    path = if options[:paths] && options[:paths][type]
             options[:paths][type]
           else
             DEFAULT_PATHS[type]
           end
    File.join(path, *args)
  end

end
