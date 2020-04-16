module Wordmove
  module Actions
    module Ssh
      module Helpers
        extend ActiveSupport::Concern

        class_methods do
          def ssh_options(remote_options:, simulate: false)
            ssh_options = remote_options[:ssh]

            if simulate == true && ssh_options[:rsync_options]
              ssh_options[:rsync_options].concat(" --dry-run")
            elsif simulate == true
              ssh_options[:rsync_options] = "--dry-run"
            end

            ssh_options
          end
        end
      end
    end
  end
end
