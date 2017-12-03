describe Wordmove::Doctor::Movefile do
  let(:movefile_name) { 'multi_environments' }
  let(:movefile_dir) { "spec/fixtures/movefiles" }
  let(:doctor) { Wordmove::Doctor::Movefile.new(movefile_name, movefile_dir) }

  context ".new" do
    it "create an Hash representing the Movefile content" do
      expect(doctor.contents).to be_a(Hash)
    end
  end

  context ".root_keys" do
    it "returns all the yml's root keys" do
      expected_root_keys = %w[
        global
        local
        staging
        production
        missing_protocol
      ]

      expect(doctor.root_keys).to eq(expected_root_keys)
    end

    context ".validate!" do
      it "calls validation on each section of the actual movefile" do
        expect(doctor).to receive(:validate_section).exactly(4).times
        expect_any_instance_of(Wordmove::Logger).to receive(:task).exactly(5).times

        silence_stream(STDOUT) { doctor.validate! }
      end
    end
  end
end
