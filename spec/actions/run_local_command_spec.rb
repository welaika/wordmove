require 'spec_helper'

describe Wordmove::Actions::RunLocalCommand do
  let(:context) do
    OrganizerContextFactory.make_for(described_class, :push)
  end

  before do
    silence_logger!
  end

  it 'works like it should' do
    result = described_class.execute(
      cli_options: context.fetch(:cli_options),
      logger: context.fetch(:logger),
      command: 'echo "Test if echo works"'
    )

    expect(result).to be_success
  end

  context 'when it fails' do
    it 'sets the expected error message into result' do
      result = described_class.execute(
        cli_options: context.fetch(:cli_options),
        logger: context.fetch(:logger),
        command: 'exit 1'
      )

      expect(result).to be_failure
      expect(result.message).to eq('Local command status reports an error')
    end
  end

  context 'when `--simulate`' do
    it 'does not execute the command and result is successful' do
      context[:cli_options][:simulate] = true

      result = described_class.execute(
        cli_options: context.fetch(:cli_options),
        logger: context.fetch(:logger),
        command: 'exit 1'
      )

      expect(result).to be_success
    end
  end
end
