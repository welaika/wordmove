describe Wordmove::CLI do
  let(:cli) { described_class.new }
  let(:deployer) { double("deployer") }
  let(:options) do {} end

  before do
    allow(Wordmove::Deployer::Base).to receive(:deployer_for).with(options).and_return(deployer)
  end

  context "#init" do
    it "delagates the command to the Movefile Generator" do
      expect(Wordmove::Generators::Movefile).to receive(:start)
      cli.invoke(:init, [], options)
    end
  end

  context "--all" do
    let(:options) do { "all" => true } end
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
