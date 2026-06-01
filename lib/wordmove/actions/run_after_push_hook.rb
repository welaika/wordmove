module Wordmove
  module Actions
    # Runs after push hooks by invoking the external service
    # Wordmove::Hook
    class RunAfterPushHook
      extend ::LightService::Action
      include Wordmove::Actions::Helpers

      expects :movefile,
              :cli_options

      # @!method execute
      #   @param movefile [Wordmove::Movefile]
      #   @param cli_options [Hash]
      #   @return [LightService::Context] Action's context
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
