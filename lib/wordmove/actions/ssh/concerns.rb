module Wordmove
  module Actions
    module Ssh
      class Concerns
        extend ActiveSupport::Concern

        class_methods do
          def ssh_options(options:)
            ssh_options = remote_options(options: options)[:ssh]

            if simulate?(options: options) && ssh_options[:rsync_options]
              ssh_options[:rsync_options].concat(" --dry-run")
            elsif simulate?(options: options)
              ssh_options[:rsync_options] = "--dry-run"
            end
          end
        end
      end
    end
  end
end
