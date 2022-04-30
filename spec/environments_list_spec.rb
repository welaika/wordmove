describe Wordmove::EnvironmentsList do
  let(:instance) { described_class.new(options) }
  let(:options) { { config: movefile_path_for('multi_environments') } }

  describe '.print' do
    subject { described_class.print(options) }

    it 'create new instance and call its #print' do
      expect_any_instance_of(described_class).to receive(:print).once
      subject
    end
  end

  describe '.new' do
    subject { instance }

    it 'created instance has logger' do
      expect(subject.respond_to?(:logger, true)).to be_truthy
    end

    it 'created instance has movefile' do
      expect(subject.respond_to?(:movefile, true)).to be_truthy
    end
  end

  describe '#print' do
    subject { instance.print }

    context 'non exist movefile' do
      let(:options) { { config: 'non_exists_path' } }
      it 'call parse_content' do
        expect { subject }.to raise_error Wordmove::MovefileNotFound
      end
    end

    context 'valid movefile' do
      it 'call parse_content' do
        expect(instance).to receive(:parse_movefile).and_call_original
        subject
      end
    end
  end

  describe 'private #output_string' do
    subject { instance.send(:output_string, vhost_list:) }

    let(:vhost_list) do
      [
        { env: :staging, vhost: 'https://staging.mysite.example.com' },
        { env: :development, vhost: 'http://development.mysite.example.com' }
      ]
    end

    it 'return expected output' do
      result = subject
      expect(result).to match('staging: https://staging.mysite.example.com')
      expect(result).to match('development: http://development.mysite.example.com')
    end
  end

  describe 'private #select_vhost' do
    subject { instance.send(:select_vhost, contents:) }

    let(:contents) do
      {
        local: {
          vhost: 'http://localhost:8080',
          wordpress_path: '/home/welaika/sites/your_site',
          database: {
            name: 'database_name',
            user: 'user',
            password: 'password',
            host: 'host'
          }
        },
        development: {
          vhost: 'http://development.mysite.example.com',
          wordpress_path: '/var/www/your_site',
          database: {
            name: 'database_name',
            user: 'user',
            password: 'password',
            host: 'host'
          }
        }
      }
    end

    let(:result_list) do
      [
        { env: :local, vhost: 'http://localhost:8080' },
        { env: :development, vhost: 'http://development.mysite.example.com' }
      ]
    end

    it 'return expected vhost list' do
      expect(subject).to match(result_list)
    end
  end
end
