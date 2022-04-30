require 'spec_helper'

describe Wordmove::Actions::RunBeforePullHook do
  let(:context) do
    OrganizerContextFactory.make_for(described_class, :pull)
  end

  before do
    silence_logger!
  end

  it 'works like it should' do
    expect(Wordmove::Hook).to receive(:run).with(
      :pull,
      :before,
      movefile: context.fetch(:movefile),
      simulate: false
    )

    result = described_class.execute(
      movefile: context.fetch(:movefile),
      cli_options: context.fetch(:cli_options)
    )

    expect(result).to be_success
  end
end
