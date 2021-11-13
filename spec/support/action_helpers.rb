require 'support/fixture_helpers'
require 'light-service/testing'

# Test helper class to build the context for Push and Pull organizers.
class OrganizerContextFactory
  extend ::FixtureHelpers
  include Wordmove::Actions::Ssh::Helpers

  DEFAULT_OPTIONS = {
    wordpress: false,
    uploads: false,
    themes: false,
    plugins: false,
    mu_plugins: false,
    languages: false,
    db: false,
    verbose: false,
    simulate: false,
    # environment is not set neither `nil`,
    config: movefile_path_for('Movefile'),
    debug: false,
    no_adapt: false,
    all: false
  }.freeze

  # Build the context for Push or Pull organizer.
  # @param [String] action
  # @param [String|Symbol] wordmove_action. Atm only :push or :pull exist
  # @param [Hash] cli_options
  #   While we have +DEFAULT_OPTIONS+, any option passed into this Hash
  #   will overwrite the default one. It is really useful to build context
  #   based on different fixturized movefiles
  # @example
  #   OrganizerContextFactory.make_for(
  #     described_class,
  #     :push,
  #     cli_options: { config: movefile_path_for('multi_environments')}
  #   )
  def self.make_for(action, wordmove_action, cli_options: {})
    cli_options = DEFAULT_OPTIONS.merge(cli_options)
    movefile = Wordmove::Movefile.new(cli_options, nil, false)

    LightService::Configuration.logger = ::Logger.new($stdout) if cli_options[:debug]

    LightService::Testing::ContextFactory
      .make_from("Wordmove::Organizers::Ssh::#{wordmove_action.to_s.camelize}".constantize)
      .for(action)
      .with(
        cli_options: cli_options,
        movefile: movefile
      )
  end
end

module ActionHelpers
  # Calling this method inside an example or inside a `before` block
  # will silence the logger using `/dev/null` as target device.
  # Note that you have to call this mocking method before `context` is
  # initialized, in order to have the mocked logger right into the context.
  def silence_logger!
    allow(Wordmove::Logger).to receive(:new).and_return(Wordmove::Logger.new('/dev/null'))
  end
end

RSpec.configure do |config|
  config.include ActionHelpers
end
