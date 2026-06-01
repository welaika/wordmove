describe Wordmove::Doctor do
  describe '.start' do
    let(:movefile_doctor) { instance_double(Wordmove::Doctor::Movefile, validate!: true) }
    let(:mysql_doctor)    { instance_double(Wordmove::Doctor::Mysql, check!: true) }
    let(:wpcli_doctor)    { instance_double(Wordmove::Doctor::Wpcli, check!: true) }
    let(:rsync_doctor)    { instance_double(Wordmove::Doctor::Rsync, check!: true) }
    let(:ssh_doctor)      { instance_double(Wordmove::Doctor::Ssh, check!: true) }

    before do
      allow(Wordmove::Doctor::Movefile).to receive(:new).and_return(movefile_doctor)
      allow(Wordmove::Doctor::Mysql).to receive(:new).and_return(mysql_doctor)
      allow(Wordmove::Doctor::Wpcli).to receive(:new).and_return(wpcli_doctor)
      allow(Wordmove::Doctor::Rsync).to receive(:new).and_return(rsync_doctor)
      allow(Wordmove::Doctor::Ssh).to receive(:new).and_return(ssh_doctor)
    end

    it 'runs movefile doctor' do
      described_class.start
      expect(movefile_doctor).to have_received(:validate!)
    end

    it 'runs mysql doctor' do
      described_class.start
      expect(mysql_doctor).to have_received(:check!)
    end

    it 'runs wpcli doctor' do
      described_class.start
      expect(wpcli_doctor).to have_received(:check!)
    end

    it 'runs rsync doctor' do
      described_class.start
      expect(rsync_doctor).to have_received(:check!)
    end

    it 'runs ssh doctor' do
      described_class.start
      expect(ssh_doctor).to have_received(:check!)
    end
  end
end
