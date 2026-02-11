describe Wordmove::Doctor::Rsync do
  subject(:doctor) { described_class.new }

  let(:logger) { double('logger', task: nil, success: nil, error: nil) }

  before do
    allow(logger).to receive(:level=)
    allow(Logger).to receive(:new).and_return(logger)
  end

  it "responds to #check!" do
    expect(doctor).to respond_to(:check!)
  end

  context "when GNU rsync is installed" do
    before do
      allow(doctor).to receive(:`).with("rsync --version | head -n1 2>&1")
                                  .and_return("rsync 3.2.7  protocol version 31\n")
    end

    it "logs the detected version" do
      doctor.check!

      expect(logger).to have_received(:success)
        .with("rsync is installed at version 3.2.7")
    end
  end

  context "when openrsync is installed" do
    before do
      allow(doctor).to receive(:`).with("rsync --version | head -n1 2>&1")
                                  .and_return("openrsync: protocol version 29\n")
    end

    it "logs the detected protocol version" do
      doctor.check!

      expect(logger).to have_received(:success)
        .with("openrsync detected (protocol version 29)")
    end
  end

  context "when rsync is missing" do
    before do
      allow(doctor).to receive(:`).with("rsync --version | head -n1 2>&1")
                                  .and_return("command not found: rsync\n")
    end

    it "logs an error" do
      doctor.check!

      expect(logger).to have_received(:error)
        .with(
          a_string_including("rsync not found or the version could not be detected.")
        )
    end
  end
end
