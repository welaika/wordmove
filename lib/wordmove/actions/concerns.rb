module Wordmove
  module Actions
    module Helpers
      extend ActiveSupport::Concern

      class_methods do
        def remote_options(options:, movefile:)
          options[movefile.environment]
        end

        def local_options(options:)
          options[:local]
        end

        def simulate?(options:)
          options[:simulate]
        end

        def paths_to_exclude(options:, movefile:)
          remote_options(options: options, movefile: movefile)[:exclude] || []
        end

        def exclude_dir_contents(path:)
          "#{path}/*"
        end
      end
    end
  end
end
