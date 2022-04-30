require 'spec_helper'

describe Wordmove::Actions::SetupContextForDb do
  let(:stubbed_actions) do
    [
      Wordmove::Actions::Ssh::BackupRemoteDb,
      Wordmove::Actions::AdaptLocalDb,
      Wordmove::Actions::Ssh::PutAndImportDumpRemotely,
      Wordmove::Actions::Ssh::CleanupAfterAdapt
    ]
  end

  before do
    # Note we're stubbing subsequent actions from organizer.
    # This stubs could be useful for using spies on classes.
    stubbed_actions.each do |action|
      stub_action(action)
    end
  end

  context 'when is required to push/pull db' do
    let(:context) do
      OrganizerContextFactory.make_for(described_class, :push, cli_options: { db: true })
    end

    it 'execute remaining actions' do
      result = described_class.execute(context)
      expect(result.db_paths).to be DbPathsConfig
    end
  end
end
