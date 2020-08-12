module Wordmove
  module Actions
    module Ssh
      module BuiltinAdapter
        class PushDb
          extend ::LightService::Action

          executed do |_context|
            raise NotImplementedError
          end
        end
      end
    end
  end
end
