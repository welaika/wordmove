describe Wordmove::CLI do
  let(:cli) { described_class.new }
  let(:deployer) { double("deployer") }
  let(:options) { {} }

  before do
    allow(Wordmove::Deployer::Base).to receive(:deployer_for).with(options).and_return(deployer)
  end

  context "#init" do
    it "delagates the command to the Movefile Generator" do
      expect(Wordmove::Generators::Movefile).to receive(:start)
      cli.invoke(:init, [], options)
    end
  end

  context "#pull" do
    context "without a movefile" do
      it "it rescues from a MovefileNotFound exception" do
        expect { cli.invoke(:pull, []) }.to raise_error SystemExit
      end
    end
  end

  context "#push" do
    context "without a movefile" do
      it "it rescues from a MovefileNotFound exception" do
        expect { cli.invoke(:pull, []) }.to raise_error SystemExit
      end
    end
  end

  context "--all" do
    let(:options) { { "all" => true } }
    let(:ordered_components) { %w(wordpress uploads themes plugins mu_plugins languages db) }

    context "#pull" do
      it "invokes commands in the right order" do
        ordered_components.each do |component|
          expect(deployer).to receive("pull_#{component}")
        end
        cli.invoke(:pull, [], options)
      end
    end

    context "#push" do
      it "invokes commands in the right order" do
        ordered_components.each do |component|
          expect(deployer).to receive("push_#{component}")
        end
        cli.invoke(:push, [], options)
      end
    end
  end
end
