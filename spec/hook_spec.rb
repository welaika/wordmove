require 'spec_helper'

describe Wordmove::Hook do
  let(:common_options) { { "wordpress" => true, "config" => movefile_path_for('with_hooks') } }
  let(:cli) { Wordmove::CLI.new }

  context "#run" do
    before do
      allow_any_instance_of(Wordmove::Deployer::Base)
        .to receive(:pull_wordpress)
        .and_return(true)

      allow_any_instance_of(Wordmove::Deployer::Base)
        .to receive(:push_wordpress)
        .and_return(true)
    end

    context "when pushing to a remote with ssh" do
      before do
        allow_any_instance_of(Photocopier::SSH)
          .to receive(:exec!)
          .with(String)
          .and_return(['Stubbed remote stdout', nil, 0])
      end

      let(:options) { common_options.merge("environment" => 'ssh_with_hooks') }
      it "runs registered before local hooks" do
        expect { cli.invoke(:push, [], options) }
          .to output(/Calling hook push before local/)
          .to_stdout_from_any_process
      end
      it "runs registered before remote hooks" do
        expect { cli.invoke(:push, [], options) }
          .to output(/Calling hook push before remote/)
          .to_stdout_from_any_process
      end
      it "runs registered after local hooks" do
        expect { cli.invoke(:push, [], options) }
          .to output(/Calling hook push after local/)
          .to_stdout_from_any_process
      end
      it "runs registered after remote hooks" do
        expect { cli.invoke(:push, [], options) }
          .to output(/Calling hook push after remote/)
          .to_stdout_from_any_process
      end
    end

    context "when pulling from a remote with ssh" do
      before do
        allow_any_instance_of(Photocopier::SSH)
          .to receive(:exec!)
          .with(String)
          .and_return(['Stubbed remote stdout', nil, 0])
      end

      let(:options) { common_options.merge("environment" => 'ssh_with_hooks') }
      it "runs registered before local hooks" do
        expect { cli.invoke(:pull, [], options) }
          .to output(/Calling hook pull before local/)
          .to_stdout_from_any_process
      end
      it "runs registered before remote hooks" do
        expect { cli.invoke(:pull, [], options) }
          .to output(/Calling hook pull before remote/)
          .to_stdout_from_any_process
      end
      it "runs registered after local hooks" do
        expect { cli.invoke(:pull, [], options) }
          .to output(/Calling hook pull after local/)
          .to_stdout_from_any_process
      end
      it "runs registered after remote hooks" do
        expect { cli.invoke(:pull, [], options) }
          .to output(/Calling hook pull after remote/)
          .to_stdout_from_any_process
      end
      it "return remote stdout" do
        expect { cli.invoke(:pull, [], options) }
          .to output(/Stubbed remote stdout/)
          .to_stdout_from_any_process
      end

      context "with remote error" do
        before do
          allow_any_instance_of(Photocopier::SSH)
            .to receive(:exec!)
            .with(String)
            .and_return(['Stubbed remote stdout', 'Stubbed remote stderr', 1])
        end

        it "returns remote stdout" do
          expect { cli.invoke(:pull, [], options) }
            .to output(/Stubbed remote stderr/)
            .to_stdout_from_any_process
        end
      end
    end

    context "when pushing to a remote with ftp" do
      let(:options) { common_options.merge("environment" => 'ftp_with_hooks') }

      context "having remote hooks" do
        it "does not run the remote hooks" do
          expect(Wordmove::Hook::Remote)
            .to_not receive(:run)

          silence_stream(STDOUT) do
            cli.invoke(:push, [], options)
          end
        end
      end
    end

    context "with hooks partially filled" do
      let(:options) { common_options.merge("environment" => 'ssh_with_hooks_partially_filled') }

      it "works silently ignoring push hooks are not present" do
        expect(Wordmove::Hook::Remote)
          .to_not receive(:run)
        expect(Wordmove::Hook::Local)
          .to_not receive(:run)

        silence_stream(STDOUT) do
          cli.invoke(:push, [], options)
        end
      end

      it "works silently ignoring 'before' step is not present" do
        expect { cli.invoke(:pull, [], options) }
          .to output(/I've partially configured my hooks/)
          .to_stdout_from_any_process
      end
    end
  end
end

describe Wordmove::Hook::Config do
  let(:movefile) { Wordmove::Movefile.new(movefile_path_for('with_hooks')) }
  let(:options) { movefile.fetch(false)[:ssh_with_hooks][:hooks] }
  let(:config) { described_class.new(options, :push, :before) }

  context "#local_hooks" do
    it "returns all the local hooks" do
      expect(config.local_hooks).to eq ['echo "Calling hook push before local"']
    end
  end

  context "#remote_hooks" do
    it "returns all the remote hooks" do
      expect(config.remote_hooks).to eq ['echo "Calling hook push before remote"']
    end
  end

  context "#empty?" do
    it "returns true if both local and remote hooks are empty" do
      allow(config).to receive(:local_hooks).and_return([])
      allow(config).to receive(:remote_hooks).and_return([])

      expect(config.empty?).to be true
    end

    it "returns false if there is at least one hook registered" do
      allow(config).to receive(:local_hooks).and_return([])

      expect(config.empty?).to be false
    end
  end
end
