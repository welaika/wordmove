module Wordmove
  module Actions
    module Ssh
      module BuiltinAdapter
        class PullDb
          extend ::LightService::Action

          executed do |_context|
            raise NotImplementedError
          end
        end
      end
    end
  end
end
