module Wordmove
  module Actions
    # Runs before push hooks by invoking the external service
    # Wordmove::Hook
    class RunBeforePushHook
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
          :before,
          movefile: context.movefile,
          simulate: simulate?(cli_options: context.cli_options)
        )
      end
    end
  end
end
