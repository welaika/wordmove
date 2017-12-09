describe Wordmove::Doctor::Wpcli do
  let(:doctor) { described_class.new }

  context ".new" do
    it "implements #check! method" do
      expect_any_instance_of(described_class).to receive(:check!)

      silence_stream(STDOUT) { doctor.check! }
    end
  end
end
