require 'spec_helper'

describe Wordmove::Actions::PutFile do
  let(:context) do
    OrganizerContextFactory.make_for(described_class, :push)
  end

  before do
    silence_logger!
  end

  it 'works like it should' do
    allow(context[:photocopier]).to receive(:put).and_return(true)

    result = described_class.execute(
      photocopier: context.fetch(:photocopier),
      logger: context.fetch(:logger),
      command_args: %w[bar foo]
    )
    expect(result).to be_success
  end

  context 'when it fails due to photocopier error' do
    it 'set the expected error message into result' do
      allow(context[:photocopier]).to receive(:put).and_return(false)

      result = described_class.execute(
        photocopier: context.fetch(:photocopier),
        logger: context.fetch(:logger),
        command_args: %w[bar foo]
      )
      expect(result).to be_failure
      expect(result.message).to eq('Failed to upload file: bar')
    end
  end
end
