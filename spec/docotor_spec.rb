describe Wordmove::Doctor do
  context "#start" do
    it "calls all movefile doctor" do
      movefile_doctor = double(:movefile_doctor)
      allow(Wordmove::Doctor::Movefile).to receive(:new).and_return(movefile_doctor)
      expect(movefile_doctor).to receive(:validate!)

      mysql_doctor = double(:mysql_doctor)
      allow(Wordmove::Doctor::Mysql).to receive(:new).and_return(mysql_doctor)
      expect(mysql_doctor).to receive(:check!)

      described_class.start
    end
  end
end
