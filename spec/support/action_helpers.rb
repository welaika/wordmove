require 'support/fixture_helpers'
require 'light-service/testing'

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
    }

  def self.make_for(action, wordmove_action, cli_options: {})
    cli_options = DEFAULT_OPTIONS.merge(cli_options)
    movefile = Wordmove::Movefile.new(cli_options, nil, false)

    LightService::Configuration.logger = ::Logger.new($stdout) if cli_options[:debug]

    LightService::Testing::ContextFactory
      .make_from("Wordmove::Actions::Ssh::#{wordmove_action.to_s.camelize}".constantize)
      .for(action)
      .with(
          cli_options: cli_options,
          movefile: movefile
      )
  end
end

module ActionHelpers
  def silence_logger!
    allow(Wordmove::Logger).to receive(:new).and_return(Wordmove::Logger.new('/dev/null'))
  end
end

RSpec.configure do |config|
  config.include ActionHelpers
end
