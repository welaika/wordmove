require 'spec_helper'

describe Wordmove::Actions::Ssh::WpcliAdapter::SetupContextForDb do
  let(:stubbed_actions) do
    [
      Wordmove::Actions::Ssh::WpcliAdapter::BackupRemoteDb,
      Wordmove::Actions::Ssh::WpcliAdapter::AdaptLocalDb,
      Wordmove::Actions::Ssh::PutAndImportDumpRemotely,
      Wordmove::Actions::Ssh::CleanupAfterAdapt
    ]
  end

  before do
    # Note we're stubbing subsequent actions from organizer.
    # This stubs could be useful for using spies on classes.
    stubbed_actions.each do |action|
      allow(action).to receive(:execute)
    end
  end

  context 'when is not required to push/pull db' do
    let(:context) do
      OrganizerContextFactory.make_for(described_class, :push, cli_options: { db: false })
    end

    it 'skips remaining actions' do
      result = described_class.execute(context)
      expect(result.skip_remaining?).to be true
    end
  end

  context 'when is required to push/pull db' do
    let(:context) do
      OrganizerContextFactory.make_for(described_class, :push, cli_options: { db: true })
    end

    it 'execute remaining actions' do
      result = described_class.execute(context)
      expect(result.skip_remaining?).to be false
    end
  end
end
