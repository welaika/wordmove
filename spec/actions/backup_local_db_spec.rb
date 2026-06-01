require 'spec_helper'

# I know these tests are very weak. I don't know how to make them sturdier
# and having them is better than nothing :)
describe Wordmove::Actions::BackupLocalDb do
  let(:context) do
    OrganizerContextFactory.make_for(described_class, :pull, cli_options: { db: true })
  end

  let(:stubbed_actions) do
    [
      Wordmove::Actions::Ssh::DownloadRemoteDb
    ]
  end

  before do
    silence_logger!
    # Note we're stubbing subsequent actions from organizer.
    # This stubs could be useful for using spies on classes.
    stubbed_actions.each do |action|
      stub_action(action)
    end
  end

  it 'works like it should' do
    allow(described_class).to receive(:system).and_return(true)

    result = described_class.execute(
      context
    )

    expect(result).to be_success
  end

  context 'when system dump command fails' do
    before do
      allow(described_class)
        .to receive(:system)
        .with(/wp db export/, exception: true)
        .and_raise(RuntimeError.new('Foo'))
    end

    it 'fails and reports the error' do
      result = described_class.execute(
        context
      )

      aggregate_failures do
        expect(result).to be_failure
        expect(result.message).to match('Foo')
      end
    end
  end

  context 'when system compress command fails' do
    before do
      allow(described_class)
        .to receive(:system)
        .with(/wp db export/, exception: true)

      allow(described_class)
        .to receive(:system)
        .with(/gzip/, exception: true)
        .and_raise(RuntimeError.new('Bar'))
    end
    it 'fails and reports the error' do
      result = described_class.execute(
        context
      )

      aggregate_failures do
        expect(result).to be_failure
        expect(result.message).to match('Bar')
      end
    end
  end
end
