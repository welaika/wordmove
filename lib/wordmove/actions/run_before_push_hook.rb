module Wordmove
  module Actions
    class RunBeforePushHook
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      expects :movefile
      expects :cli_options

      executed do |context|
        Wordmove::Hook.run(
          :push,
          :before,
          movefile: context.movefile,
          simulate: simulate?(cli_options: context.cli_options)
        )
      end
    end
  end
end
