module Wordmove
  module Actions
    # Runs before pull hooks by invoking the external service
    # Wordmove::Hook
    class RunBeforePullHook
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
          :pull,
          :before,
          movefile: context.movefile,
          simulate: simulate?(cli_options: context.cli_options)
        )
      end
    end
  end
end
