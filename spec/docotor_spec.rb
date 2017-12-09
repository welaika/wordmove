describe Wordmove::Doctor do
  context "#start" do
    it "calls all movefile doctors" do
      movefile_doctor = double(:movefile_doctor)
      allow(Wordmove::Doctor::Movefile).to receive(:new).and_return(movefile_doctor)
      expect(movefile_doctor).to receive(:validate!).exactly(1).times

      mysql_doctor = double(:mysql_doctor)
      allow(Wordmove::Doctor::Mysql).to receive(:new).and_return(mysql_doctor)
      expect(mysql_doctor).to receive(:check!).exactly(1).times

      wpcli_doctor = double(:wpcli_doctor)
      allow(Wordmove::Doctor::Wpcli).to receive(:new).and_return(wpcli_doctor)
      expect(wpcli_doctor).to receive(:check!).exactly(1).times

      rsync_doctor = double(:rsync_doctor)
      allow(Wordmove::Doctor::Rsync).to receive(:new).and_return(rsync_doctor)
      expect(rsync_doctor).to receive(:check!).exactly(1).times

      ssh_doctor = double(:ssh_doctor)
      allow(Wordmove::Doctor::Ssh).to receive(:new).and_return(ssh_doctor)
      expect(ssh_doctor).to receive(:check!).exactly(1).times

      described_class.start
    end
  end
end
