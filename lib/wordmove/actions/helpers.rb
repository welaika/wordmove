module Wordmove
  module Actions
    module Helpers
      extend ActiveSupport::Concern

      class_methods do
        # def remote_options(options:, environment:)
        #   options[environment]
        # end

        # def local_options(options:)
        #   options[:local]
        # end

        def simulate?(cli_options:)
          cli_options.fetch(:simulate, false)
        end

        def paths_to_exclude(remote_options:)
          remote_options.fetch(:exclude, [])
        end

        def exclude_dir_contents(path:)
          "#{path}/*"
        end
      end
    end
  end
end
