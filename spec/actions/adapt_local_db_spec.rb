require 'spec_helper'

# I know these tests are very weak. I don't know how to make them sturdier
# and having them is better than nothing :)
describe Wordmove::Actions::AdaptLocalDb do
  let(:context) do
    OrganizerContextFactory.make_for(described_class, :push, cli_options: { db: true })
  end

  let(:stubbed_actions) do
    [
      Wordmove::Actions::Ssh::DownloadRemoteDb,
      Wordmove::Actions::Ssh::BackupRemoteDb
    ]
  end

  let(:local_command_stub) { class_double('Wordmove::Actions::RunLocalCommand').as_stubbed_const }

  before do
    silence_logger!
    # Note we're stubbing subsequent actions from organizer.
    # This stubs could be useful for using spies on classes.
    stubbed_actions.each do |action|
      allow(action).to receive(:execute)
    end
    allow(local_command_stub).to receive(:execute)
  end

  it 'works like it should' do
    result = described_class.execute(
      context
    )

    aggregate_failures 'testing sub-actions' do
      expect(local_command_stub).to have_received(:execute).exactly(6).times
      expect(result).to be_success
    end
  end

  context 'when --no-adapt' do
    let(:context) do
      OrganizerContextFactory.make_for(
        described_class, :push, cli_options: { db: true, no_adapt: true }
      )
    end

    it 'works like it should' do
      result = described_class.execute(
        context
      )

      aggregate_failures 'testing sub-actions' do
        expect(local_command_stub).to have_received(:execute).exactly(4).times
        expect(result).to be_success
      end
    end
  end
end
