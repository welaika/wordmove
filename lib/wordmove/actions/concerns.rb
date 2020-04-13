module Wordmove
  module Actions
    class Concerns
      extend ActiveSupport::Concern

      class_methods do
        def remote_options(context)
          context.options[context.movefile.environment]
        end

        def local_options(options:)
          options[:local]
        end

        def simulate?(options:)
          options[:simulate]
        end

        def paths_to_exclude(context)
          remote_options(context)[:exclude] || []
        end

        def exclude_dir_contents(path:)
          "#{path}/*"
        end
      end
    end
  end
end
