require 'spec_helper'
require 'tmpdir'

describe Wordmove::Hook do
  let(:common_options) { { wordpress: true, config: movefile_path_for('with_hooks') } }
  # +options+ is meant to be defined into every single spec +context+ (I mean rspec's context
  # not service objects' context ;) )
  let(:context) do
    {
      cli_options: options,
      movefile: Wordmove::Movefile.new(options)
    }
  end

  let(:stubbed_actions) do
    [
      Wordmove::Actions::Ssh::PushWordpress,
      Wordmove::Actions::Ftp::PushWordpress,
      Wordmove::Actions::Ssh::PullWordpress,
      Wordmove::Actions::Ftp::PullWordpress,
      Wordmove::Actions::Ssh::PutDirectory,
      Wordmove::Actions::Ftp::PutDirectory,
      Wordmove::Actions::Ssh::GetDirectory,
      Wordmove::Actions::Ftp::GetDirectory,
      Wordmove::Actions::SetupContextForDb,
      Wordmove::Actions::Ssh::DownloadRemoteDb,
      Wordmove::Actions::Ftp::DownloadRemoteDb,
      Wordmove::Actions::Ssh::BackupRemoteDb,
      Wordmove::Actions::Ftp::BackupRemoteDb,
      Wordmove::Actions::AdaptLocalDb,
      Wordmove::Actions::Ssh::PutAndImportDumpRemotely,
      Wordmove::Actions::Ftp::PutAndImportDumpRemotely,
      Wordmove::Actions::BackupLocalDb,
      Wordmove::Actions::AdaptRemoteDb,
      Wordmove::Actions::Ssh::CleanupAfterAdapt,
      Wordmove::Actions::Ftp::CleanupAfterAdapt
    ]
  end

  before do
    # Note we're stubbing actions from organizers others than ones
    # calling the hooks. I consider this approach to be affordable enough.
    stubbed_actions.each do |action|
      stub_action(action)
    end
  end

  context 'testing command order' do
    let(:options) { common_options.merge(environment: 'ssh_with_hooks') }

    before do
      allow(Wordmove::Hook::Local).to receive(:run)
      allow(Wordmove::Hook::Remote).to receive(:run)
    end

    it 'checks the order' do
      Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile])

      expect(Wordmove::Hook::Local).to(
        have_received(:run).with(
          { command: 'echo "Calling hook push before local"', where: 'local' },
          an_instance_of(Hash),
          false
        ).ordered
      )
      expect(Wordmove::Hook::Local).to(
        have_received(:run).with(
          { command: 'pwd', where: 'local' },
          an_instance_of(Hash),
          false
        ).ordered
      )
      expect(Wordmove::Hook::Remote).to(
        have_received(:run).with(
          { command: 'echo "Calling hook push before remote"', where: 'remote' },
          an_instance_of(Hash),
          false
        ).ordered
      )

      expect(Wordmove::Hook::Local).to(
        have_received(:run).with(
          { command: 'echo "Calling hook push after local"', where: 'local' },
          an_instance_of(Hash),
          false
        ).ordered
      )
      expect(Wordmove::Hook::Remote).to(
        have_received(:run).with(
          { command: 'echo "Calling hook push after remote"', where: 'remote' },
          an_instance_of(Hash),
          false
        ).ordered
      )
    end
  end

  context '#run' do
    context 'when pushing to a remote with ssh' do
      before do
        allow_any_instance_of(Photocopier::SSH)
          .to receive(:exec!)
          .with(String)
          .and_return(['Stubbed remote stdout', nil, 0])
      end

      let(:options) { common_options.merge(environment: 'ssh_with_hooks') }

      it 'runs registered before local hooks' do
        expect { Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook push before local/)
          .to_stdout
      end

      it 'runs registered before local hooks in the wordpress folder' do
        expect { Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile]) }
          .to output(/#{Dir.tmpdir}/)
          .to_stdout
      end

      it 'runs registered before remote hooks' do
        expect { Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook push before remote/)
          .to_stdout
      end

      it 'runs registered after local hooks' do
        expect { Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook push after local/)
          .to_stdout
      end

      it 'runs registered after remote hooks' do
        expect { Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook push after remote/)
          .to_stdout
      end

      context 'if --similate was passed by user on cli' do
        let(:options) do
          common_options.merge(environment: 'ssh_with_hooks', simulate: true)
        end

        it 'does not really run any commands' do
          expect { Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile]) }
            .not_to output(/Output:/)
            .to_stdout
        end
      end

      context 'with local hook errored' do
        let(:options) { common_options.merge(environment: 'ssh_with_hooks_which_return_error') }

        it 'logs an error and raises a LocalHookException' do
          expect do
            expect do
              Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile])
            end.to raise_exception(Wordmove::LocalHookException)
          end.to output(/Error code: 127/).to_stdout
        end

        context 'with raise set to `false`' do
          let(:options) do
            common_options.merge(environment: 'ssh_with_hooks_which_return_error_raise_false')
          end

          it 'logs an error without raising an exeption' do
            expect do
              expect do
                Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile])
              end.to_not raise_exception
            end.to output(/Error code: 127/)
              .to_stdout
          end
        end
      end
    end

    context 'when pulling from a remote with ssh' do
      before do
        allow_any_instance_of(Photocopier::SSH)
          .to receive(:exec!)
          .with(String)
          .and_return(['Stubbed remote stdout', nil, 0])
      end

      let(:options) { common_options.merge(environment: 'ssh_with_hooks') }

      it 'runs registered before local hooks' do
        expect { Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook pull before local/)
          .to_stdout
      end

      it 'runs registered before remote hooks' do
        expect { Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook pull before remote/)
          .to_stdout
      end

      it 'runs registered after local hooks' do
        expect { Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook pull after local/)
          .to_stdout
      end

      it 'runs registered after remote hooks' do
        expect { Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile]) }
          .to output(/Calling hook pull after remote/)
          .to_stdout
      end

      it 'return remote stdout' do
        expect { Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile]) }
          .to output(/Stubbed remote stdout/)
          .to_stdout
      end

      context 'with remote hook errored' do
        before do
          allow_any_instance_of(Photocopier::SSH)
            .to receive(:exec!)
            .with(String)
            .and_return(['Stubbed remote stdout', 'Stubbed remote stderr', 1])
        end

        it 'returns remote stdout and raise an exception' do
          expect do
            expect do
              Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile])
            end.to raise_exception(Wordmove::RemoteHookException)
          end.to output(/Stubbed remote stderr/)
            .to_stdout
        end

        it 'raises a RemoteHookException' do
          expect do
            silence_stream($stdout) do
              Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile])
            end
          end.to raise_exception(Wordmove::RemoteHookException)
        end
      end
    end

    context 'when pushing to a remote with ftp' do
      let(:options) { common_options.merge(environment: 'ftp_with_hooks') }

      context 'having remote hooks' do
        it 'does not run the remote hooks and alert the user' do
          expect(Wordmove::Hook::Remote)
            .to_not receive(:run)

          expect { Wordmove::Organizers::Ftp::Push.call(context[:cli_options], context[:movefile]) }
            .to output(
              /You have configured remote hooks to run over an FTP connection, but this is not possible/ # rubocop:disable Layout/LineLength
            ).to_stdout
        end
      end
    end

    context 'with hooks partially filled' do
      let(:options) { common_options.merge(environment: 'ssh_with_hooks_partially_filled') }

      it 'works silently ignoring push hooks are not present' do
        expect(Wordmove::Hook::Remote)
          .to_not receive(:run)
        expect(Wordmove::Hook::Local)
          .to_not receive(:run)

        silence_stream($stdout) do
          Wordmove::Organizers::Ssh::Push.call(context[:cli_options], context[:movefile])
        end
      end

      it "works silently ignoring 'before' step is not present" do
        expect { Wordmove::Organizers::Ssh::Pull.call(context[:cli_options], context[:movefile]) }
          .to output(/I've partially configured my hooks/)
          .to_stdout
      end
    end
  end
end

describe Wordmove::Hook::Config do
  let(:movefile) { Wordmove::Movefile.new({ config: movefile_path_for('with_hooks') }, nil, false) }
  let(:options) { movefile.options[:ssh_with_hooks][:hooks] }
  let(:config) { described_class.new(options, :push, :before) }

  context '#local_commands' do
    it 'returns all the local hooks' do
      expect(config.remote_commands).to be_kind_of(Array)
      expect(config.local_commands.first[:command]).to eq 'echo "Calling hook push before local"'
      expect(config.local_commands.second[:command]).to eq 'pwd'
    end
  end

  context '#remote_commands' do
    it 'returns all the remote hooks' do
      expect(config.remote_commands).to be_kind_of(Array)
      expect(config.remote_commands.first[:command]).to eq 'echo "Calling hook push before remote"'
    end
  end

  context '#empty?' do
    it 'returns true if `all_commands` array is empty' do
      allow(config).to receive(:all_commands).and_return([])

      expect(config.empty?).to be true
    end

    it 'returns false if there is at least one hook registered' do
      allow(config).to receive(:local_commands).and_return([])

      expect(config.empty?).to be false
    end
  end
end
