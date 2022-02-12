require 'spec_helper'

describe Wordmove::Actions::Ssh::RunRemoteCommand do
  let(:context) do
    OrganizerContextFactory.make_for(described_class, :push)
  end
  let(:good_command) { 'echo "Test if echo works"' }
  let(:bad_command) { 'exit 1' }

  before do
    allow(context[:photocopier])
      .to receive(:exec!).with(good_command)
                         .and_return([nil, nil, 0])
    allow(context[:photocopier])
      .to receive(:exec!).with(bad_command)
                         .and_return([nil, 'Evil error', 666])
  end

  it 'works like it should' do
    silence_logger!

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
      silence_logger!

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
      silence_logger!

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

  context 'testing @castilma\'s big report' do
    let(:command) do
      'mysqldump --host=remote_database_host --user=user ' \
      '--password=R4ndom#+Str1nG ' \
      '--result-file="/var/www/your_site/wp-content/dump.sql" database_name'
    end

    let(:context) do
      OrganizerContextFactory.make_for(
        described_class,
        :push,
        cli_options: {
          config: movefile_path_for('with_secrets_castilma'),
          environment: :remote
        }
      )
    end

    it 'censors the password on STDOUT' do
      allow(context[:photocopier])
        .to receive(:exec!).with(command)
                           .and_return([nil, nil, 0])

      expect do
        described_class.execute(
          photocopier: context.fetch(:photocopier),
          cli_options: context.fetch(:cli_options),
          logger: context.fetch(:logger),
          command: command
        )
      end.to output(/--password=\[secret\]/).to_stdout_from_any_process
    end
  end
end
