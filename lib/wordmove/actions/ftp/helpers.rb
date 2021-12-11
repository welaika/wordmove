module Wordmove
  module Actions
    module Ssh
      module Helpers
        extend ActiveSupport::Concern

        class_methods do
          def ftp_options(remote_options:)
            remote_options[:ftp]
          end
        end
      end
    end
  end
end
