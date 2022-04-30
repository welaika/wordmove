describe Wordmove::Movefile do
  let(:path) { File.join(tmpdir, 'movefile.yml') }
  let(:movefile) { described_class.new(config: movefile_path_for('Movefile')) }

  context '.initialize' do
    it 'instantiate a logger instance' do
      expect(movefile.logger).to be_an_instance_of(Wordmove::Logger)
    end
  end

  context '#load_env' do
    let(:tmpdir) { '/tmp/wordmove'.freeze }
    let(:path) { File.join(tmpdir, 'movefile.yml') }
    let(:dotenv_path) { File.join(tmpdir, '.env') }
    let(:yaml) { "name: Waldo\njob: Hider" }
    let(:dotenv) { 'OBIWAN=KENOBI' }
    let(:movefile) { described_class.new({ config: 'movefile.yml' }, path) }

    before do
      FileUtils.mkdir(tmpdir)
      File.write(path, yaml)
      File.write(dotenv_path, dotenv)
      allow_any_instance_of(described_class)
        .to receive(:current_dir)
        .and_return(tmpdir)
      allow_any_instance_of(described_class)
        .to receive(:logger)
        .and_return(double('logger').as_null_object)
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    context 'when .env is present' do
      let!(:movefile) do
        described_class.new(
          {
            config: 'movefile.yml',
            environment: 'local'
          },
          path
        )
      end

      it 'loads environment variables' do
        expect(ENV['OBIWAN']).to eq('KENOBI')
      end
    end
  end

  context '#fetch' do
    let(:tmpdir) { '/tmp/wordmove'.freeze }

    let(:path) { File.join(tmpdir, 'movefile.yml') }
    let(:yaml) { "name: Waldo\njob: Hider" }
    let(:movefile) { described_class.new({}, path) }

    before do
      FileUtils.mkdir(tmpdir)
      File.write(path, yaml)
      allow_any_instance_of(described_class)
        .to receive(:current_dir)
        .and_return(tmpdir)
      allow_any_instance_of(described_class)
        .to receive(:logger)
        .and_return(double('logger').as_null_object)
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    context 'when Movefile is missing' do
      it 'raises an exception' do
        expect { described_class.new({}, '/tmp') }.to raise_error(Wordmove::MovefileNotFound)
      end
    end

    context 'when Movefile is present' do
      it 'finds a Movefile in current dir' do
        result = movefile.options
        expect(result[:name]).to eq('Waldo')
        expect(result[:job]).to eq('Hider')
      end

      context 'when movefile has no extensions' do
        let(:path) { File.join(tmpdir, 'movefile') }

        it 'finds it aswell' do
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context 'when Movefile has no extensions and has first capital' do
        let(:path) { File.join(tmpdir, 'Movefile') }

        it 'finds it aswell' do
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context 'when movefile.yaml has long extension' do
        let(:path) { File.join(tmpdir, 'movefile.yaml') }

        it 'finds it aswell' do
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end
      end

      context 'directories traversal' do
        before do
          @test_dir = File.join(tmpdir, 'test')
          FileUtils.mkdir(@test_dir)
        end

        it 'goes up through the directory tree and finds it' do
          movefile = described_class.new({}, @test_dir)
          result = movefile.options
          expect(result[:name]).to eq('Waldo')
          expect(result[:job]).to eq('Hider')
        end

        context 'Movefile not found, met root node' do
          let(:movefile) { described_class.new({}, '/tmp') }

          it 'raises an exception' do
            expect { movefile.fetch }.to raise_error(Wordmove::MovefileNotFound)
          end
        end

        context 'Movefile not found, found wp-config.php' do
          let(:movefile) { described_class.new({}, '/tmp') }

          before do
            FileUtils.touch(File.join(@test_dir, 'wp-config.php'))
          end

          it 'raises an exception' do
            expect { movefile.fetch }.to raise_error(Wordmove::MovefileNotFound)
          end
        end
      end
    end
  end

  context '#secrets' do
    let(:path) { movefile_path_for('with_secrets') }

    it 'returns all the secrets found in movefile' do
      movefile = described_class.new(config: path)
      expect(movefile.secrets).to eq(
        %w[
          local_database_password
          local_database_host
          http://example.com
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

    it 'returns all the secrets found in movefile excluding empty string values' do
      allow(Wordmove::WpcliHelpers)
        .to receive(:get_config)
        .with('DB_PASSWORD', config_path: instance_of(String))
        .and_return('')

      path = movefile_path_for('with_secrets_with_empty_local_db_password')
      movefile = described_class.new(config: path)
      expect(movefile.secrets).to eq(
        %w[
          local_database_host
          http://example.com
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

  context '#environment' do
    let!(:movefile) do
      described_class.new(
        config: movefile_path_for('multi_environments'),
        environment: nil
      )
    end

    context 'with more than one environment, but none chosen' do
      it 'raises an exception' do
        expect { movefile.environment }
          .to raise_exception(Wordmove::UndefinedEnvironment)
      end
    end

    context 'with more than one environment, but invalid chosen' do
      let!(:movefile) do
        described_class.new(
          config: movefile_path_for('multi_environments'),
          environment: 'doesnotexist'
        )
      end
      it 'raises an exception' do
        expect { movefile.environment }
          .to raise_exception(Wordmove::UndefinedEnvironment)
      end
    end
  end
end
