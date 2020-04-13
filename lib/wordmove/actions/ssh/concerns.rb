module Wordmove
  module Actions
    module Ssh
      module Helpers
        extend ActiveSupport::Concern

        class_methods do
          def ssh_options(options:, movefile:)
            ssh_options = remote_options(options: options, movefile: movefile)[:ssh]

            if simulate?(options: options) && ssh_options[:rsync_options]
              ssh_options[:rsync_options].concat(" --dry-run")
            elsif simulate?(options: options)
              ssh_options[:rsync_options] = "--dry-run"
            end

            ssh_options
          end
        end
      end
    end
  end
end
