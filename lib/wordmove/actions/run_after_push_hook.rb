module Wordmove
  module Actions
    class RunAfterPushHook
      extend ::LightService::Action
      include Wordmove::Actions::Helpers

      expects :movefile,
              :cli_options

      executed do |context|
        Wordmove::Hook.run(
          :push,
          :after,
          movefile: context.movefile,
          simulate: simulate?(cli_options: context.cli_options)
        )
      end
    end
  end
end
