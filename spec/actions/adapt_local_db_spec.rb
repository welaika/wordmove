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

  before do
    silence_logger!
    # Note we're stubbing subsequent actions from organizer.
    # This stubs could be useful for using spies on classes.
    stubbed_actions.each do |action|
      stub_action(action)
    end

    allow(described_class)
      .to receive(:system)
      .and_return(true)
  end

  it 'works like it should' do
    result = described_class.execute(
      context
    )

    expect(result).to be_success
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
        expect(result).to be_success
        expect(described_class)
          .to_not have_received(:system)
          .with(/wp search-replace/, exception: true)
      end
    end
  end

  context '.search_replace_command' do
    it 'returns the expected command' do
      expect(subject.class.search_replace_command(context, :wordpress_path))
        .to eq('wp search-replace --path=~/dev/sites/your_site "\A~/dev/sites/your_site\Z" ' \
               '"/var/www/your_site" --regex-delimiter="|" --regex --precise --quiet ' \
               '--skip-columns=guid --all-tables --allow-root')
    end

    context 'when wrong config_key is passed' do
      it 'raises an error' do
        expect { subject.class.search_replace_command(context, :wrong) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
