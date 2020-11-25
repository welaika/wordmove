require 'spec_helper'

describe Wordmove::Actions::Ssh::RunRemoteCommand do
  let(:context) do
    OrganizerContextFactory.make_for(described_class, :push)
  end
  let(:good_command) { 'echo "Test if echo works"' }
  let(:bad_command) { 'exit 1' }

  before do
    silence_logger!
    allow(context[:photocopier])
      .to receive(:exec!).with(good_command)
                         .and_return([nil, nil, 0])
    allow(context[:photocopier])
      .to receive(:exec!).with(bad_command)
                         .and_return([nil, 'Evil error', 666])
  end

  it 'works like it should' do
    result = described_class.execute(
      photocopier: context.fetch(:photocopier),
      cli_options: context.fetch(:cli_options),
      logger: context.fetch(:logger),
      command: good_command
    )

    expect(result).to be_success
  end

  context 'when it fails' do
    it 'sets the expected error message into result' do
      result = described_class.execute(
        photocopier: context.fetch(:photocopier),
        cli_options: context.fetch(:cli_options),
        logger: context.fetch(:logger),
        command: bad_command
      )

      expect(result).to be_failure
      expect(result.message).to eq('Error code 666 returned by command exit 1: Evil error')
    end
  end

  context 'when `--simulate`' do
    it 'does not execute the command and result is successful' do
      context[:cli_options][:simulate] = true

      result = described_class.execute(
        photocopier: context.fetch(:photocopier),
        cli_options: context.fetch(:cli_options),
        logger: context.fetch(:logger),
        command: bad_command
      )

      expect(result).to be_success
    end
  end
end
