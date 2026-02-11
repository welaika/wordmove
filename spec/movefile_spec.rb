TMPDIR = "/tmp/wordmove".freeze
describe Wordmove::Movefile do
  let(:movefile) { described_class.new }

  context ".initialize" do
    it "instantiate a logger instance" do
      expect(movefile.logger).to be_an_instance_of(Wordmove::Logger)
    end
  end

  context ".load_env" do
    let(:path) { File.join(TMPDIR, 'movefile.yml') }
    let(:dotenv_path) { File.join(TMPDIR, '.env') }
    let(:yaml) { "name: Waldo\njob: Hider" }
    let(:dotenv) { "OBIWAN=KENOBI" }
    let(:movefile) { described_class.new(nil, path) }

    before do
      FileUtils.mkdir(TMPDIR)
      allow(movefile).to receive(:current_dir).and_return(TMPDIR)
      allow(movefile).to receive(:logger).and_return(double('logger').as_null_object)
      File.open(path, 'w') { |f| f.write(yaml) }
    end

    after do
      FileUtils.rm_rf(TMPDIR)
    end

    context "when .env is present" do
      before do
        File.open(dotenv_path, 'w') { |f| f.write(dotenv) }
      end

      it "loads environment variables" do
        movefile.load_dotenv(environment: 'local')

        expect(ENV['OBIWAN']).to eq('KENOBI')
      end
    end
  end

  context ".fetch" do
    let(:path) { File.join(TMPDIR, 'movefile.yml') }
    let(:yaml) { "name: Waldo\njob: Hider" }
    let(:movefile) { described_class.new(nil, path) }

    before do
      FileUtils.mkdir(TMPDIR)
      allow(movefile).to receive(:current_dir).and_return(TMPDIR)
      allow(movefile).to receive(:logger).and_return(double('logger').as_null_object)
    end

    after do
      FileUtils.rm_rf(TMPDIR)
    end

    context "when Movefile is missing" do
      it 'raises an exception' do
        expect { movefile.fetch }.to raise_error(Wordmove::MovefileNotFound)
      end
    end

    context "when Movefile is present" do
      before do
        File.open(path, 'w') { |f| f.write(yaml) }
      end

      it 'finds a Movefile in current dir' do
        result = movefile.fetch
        expect(result[:name]).to eq('Waldo')
        expect(result[:job]).to eq('Hider')
      end

      context "when movefile has no extensions" do
        let(:path) { File.join(TMPDIR, 'movefile') }

        it 'finds it aswell' do
          result = movefile.fetch
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context "when Movefile has no extensions and has first capital" do
        let(:path) { File.join(TMPDIR, 'Movefile') }

        it 'finds it aswell' do
          result = movefile.fetch
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context "when movefile.yaml has long extension" do
        let(:path) { File.join(TMPDIR, 'movefile.yaml') }

        it 'finds it aswell' do
          result = movefile.fetch
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context "directories traversal" do
        before do
          @test_dir = File.join(TMPDIR, "test")
          FileUtils.mkdir(@test_dir)
        end

        it 'goes up through the directory tree and finds it' do
          movefile = described_class.new(nil, @test_dir)
          result = movefile.fetch
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end

        context 'Movefile not found, met root node' do
          let(:movefile) { described_class.new(nil, '/tmp') }

          it 'raises an exception' do
            expect { movefile.fetch }.to raise_error(Wordmove::MovefileNotFound)
          end
        end

        context 'Movefile not found, found wp-config.php' do
          let(:movefile) { described_class.new(nil, '/tmp') }

          before do
            FileUtils.touch(File.join(@test_dir, "wp-config.php"))
          end

          it 'raises an exception' do
            expect { movefile.fetch }.to raise_error(Wordmove::MovefileNotFound)
          end
        end
      end
    end
  end

  context ".secrets" do
    let(:path) { movefile_path_for('with_secrets') }

    it "returns all the secrets found in movefile" do
      movefile = described_class.new('with_secrets', path)
      expect(movefile.secrets).to eq(
        %w[
          local_database_password
          local_database_host
          http://secrets.local
          ~/dev/sites/your_site
          remote_database_password
          remote_database_host
          http://secrets.example.com
          ssh_password
          ssh_host
          ftp_password
          ftp_host
          /var/www/your_site
          https://foo.bar
        ]
      )
    end

    it "returns all the secrets found in movefile excluding empty string values" do
      movefile = described_class.new('with_secrets_with_empty_local_db_password', path)
      expect(movefile.secrets).to eq(
        %w[
          local_database_host
          http://secrets.local
          ~/dev/sites/your_site
          remote_database_password
          remote_database_host
          http://secrets.example.com
          ssh_password
          ssh_host
          ftp_password
          ftp_host
          /var/www/your_site
        ]
      )
    end
  end
end
