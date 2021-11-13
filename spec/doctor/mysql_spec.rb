describe Wordmove::Doctor::Mysql do
  let(:movefile_name) { 'multi_environments' }
  let(:movefile_dir) { 'spec/fixtures/movefiles' }
  let(:doctor) { described_class.new(movefile_name, movefile_dir) }

  context '.new' do
    it 'implements #check! method' do
      expect_any_instance_of(described_class).to receive(:check!)

      silence_stream($stdout) { doctor.check! }
    end

    it 'calls mysql client check' do
      expect(doctor).to receive(:mysql_client_doctor)

      silence_stream($stdout) { doctor.check! }
    end

    it 'calls mysqldump check' do
      expect(doctor).to receive(:mysqldump_doctor)

      silence_stream($stdout) { doctor.check! }
    end

    it 'calls mysql server check' do
      expect(doctor).to receive(:mysql_server_doctor)

      silence_stream($stdout) { doctor.check! }
    end

    it 'calls mysql database check' do
      # expect(doctor).to receive(:mysql_database_doctor)

      silence_stream($stdout) { doctor.check! }
    end
  end
end
