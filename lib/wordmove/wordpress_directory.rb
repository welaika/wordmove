class WordpressDirectory
  attr_reader :folder, :options

  def initialize(folder, options)
    @folder = folder
    @options = options
  end

  module Path
    WP_CONTENT = :wp_content
    WP_CONFIG  = :wp_config
    PLUGINS    = :plugins
    MU_PLUGINS = :mu_plugins
    THEMES     = :themes
    UPLOADS    = :uploads
    LANGUAGES  = :languages
  end

  DEFAULT_PATHS = {
    Path::WP_CONTENT => 'wp-content',
    Path::WP_CONFIG => 'wp-config.php',
    Path::PLUGINS => 'wp-content/plugins',
    Path::MU_PLUGINS => 'wp-content/mu-plugins',
    Path::THEMES => 'wp-content/themes',
    Path::UPLOADS => 'wp-content/uploads',
    Path::LANGUAGES => 'wp-content/languages'
  }.freeze

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
    path = if options[:paths] && options[:paths][folder]
             options[:paths][folder]
           else
             DEFAULT_PATHS[folder]
           end
    File.join(path, *args)
  end

  module LocalHelperMethods
    extend ActiveSupport::Concern

    included do
      def remote_wp_content_dir
        WordpressDirectory.new(:wp_content, remote_options)
      end

      def remote_plugins_dir
        WordpressDirectory.new(:plugins, remote_options)
      end

      def remote_mu_plugins_dir
        WordpressDirectory.new(:mu_plugins, remote_options)
      end

      def remote_themes_dir
        WordpressDirectory.new(:themes, remote_options)
      end

      def remote_uploads_dir
        WordpressDirectory.new(:uploads, remote_options)
      end

      def remote_languages_dir
        WordpressDirectory.new(:languages, remote_options)
      end
    end
  end

  module RemoteHelperMethods
    extend ActiveSupport::Concern

    included do
      def local_wp_content_dir
        WordpressDirectory.new(:wp_content, local_options)
      end

      def local_plugins_dir
        WordpressDirectory.new(:plugins, local_options)
      end

      def local_mu_plugins_dir
        WordpressDirectory.new(:mu_plugins, local_options)
      end

      def local_themes_dir
        WordpressDirectory.new(:themes, local_options)
      end

      def local_uploads_dir
        WordpressDirectory.new(:uploads, local_options)
      end

      def local_languages_dir
        WordpressDirectory.new(:languages, local_options)
      end
    end
  end

  module HelperMethods
    include LocalHelperMethods
    include RemoteHelperMethods
  end
end
