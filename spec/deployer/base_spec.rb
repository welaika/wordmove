describe Wordmove::Deployer::Base do

  context ".deployer_for" do
    let(:options) do
      { config: movefile_path_for("multi_environments") }
    end

    context "with more then one environment, but none chosen" do
      it "raises an exception" do
        expect{ described_class.deployer_for(options) }
          .to raise_exception(Wordmove::UndefinedEnvironment)
      end
    end

    context "with ftp remote connection" do
      it "returns an instance of FTP deployer" do
        options.merge!({ "environment" => "production" })
        expect(described_class.deployer_for(options)).to be_a Wordmove::Deployer::FTP
      end
    end

    context "with ssh remote connection" do
      it "returns an instance of SSH deployer" do
        options.merge!({ "environment" => "staging" })
        expect(described_class.deployer_for(options)).to be_a Wordmove::Deployer::SSH
      end
    end

    context "with unknown type of connection " do
      it "raises an exception" do
        options.merge!({ "environment" => "missing_protocol" })
        expect{described_class.deployer_for(options)}.to raise_error(Wordmove::NoAdapterFound)
      end
    end
  end

  context ".fetch_movefile" do
    TMPDIR = "/tmp/wordmove"

    let(:path) { File.join(TMPDIR, 'Movefile') }
    let(:yaml) { "name: Waldo\njob: Hider" }

    before do
      FileUtils.mkdir(TMPDIR)
      allow(described_class).to receive(:current_dir).and_return(TMPDIR)
      allow(described_class).to receive(:logger).and_return(double('logger').as_null_object)
    end

    after do
      FileUtils.rm_rf(TMPDIR)
    end

    context "when Movefile is missing" do
      it 'raises an exception' do
        expect { described_class.fetch_movefile }.to raise_error(Wordmove::MovefileNotFound)
      end
    end

    context "when Movefile is present" do
      before do
        File.open(path, 'w') { |f| f.write(yaml) }
      end

      it 'finds a Movefile in current dir' do
        result = described_class.fetch_movefile
        expect(result['name']).to eq('Waldo')
        expect(result['job']).to eq('Hider')
      end

      context "when Movefile has extensions" do
        let(:path) { File.join(TMPDIR, 'Movefile.yml') }

        it 'finds it aswell' do
          result = described_class.fetch_movefile
          expect(result['name']).to eq('Waldo')
          expect(result['job']).to eq('Hider')
        end
      end

      context "directories traversal" do
        before do
          @test_dir = File.join(TMPDIR, "test")
          FileUtils.mkdir(@test_dir)
          allow(described_class).to receive(:current_dir).and_return(@test_dir)
        end

        it 'goes up through the directory tree and finds it' do
          result = described_class.fetch_movefile
          expect(result['name']).to eq('Waldo')
          expect(result['job']).to eq('Hider')
        end

        context 'Movefile not found, met root node' do
          it 'raises an exception' do
            allow(described_class).to receive(:current_dir).and_return('/tmp')
            expect { described_class.fetch_movefile }.to raise_error(Wordmove::MovefileNotFound)
          end
        end

        context 'Movefile not found, found wp-config.php' do
          before do
            FileUtils.touch(File.join(@test_dir, "wp-config.php"))
          end

          it 'raises an exception' do
            expect { described_class.fetch_movefile }.to raise_error(Wordmove::MovefileNotFound)
          end
        end
      end
    end
  end

  context "#mysql_dump_command" do
    let(:deployer) { described_class.new(:dummy_env) }

    it "creates a valid mysqldump command" do
      command = deployer.send(
        :mysql_dump_command,
        {
          host: "localhost",
          port: "8888",
          user: "root",
          password: "'\"$ciao",
          charset: "utf8",
          name: "database_name",
          mysqldump_options: "--max_allowed_packet=1G --no-create-db"
        },
        "./mysql dump.sql"
      )
      expect(command).to eq("mysqldump --host=localhost --port=8888 --user=root --password=\\'\\\"\\$ciao --default-character-set=utf8 --result-file=./mysql\\ dump.sql --max_allowed_packet=1G --no-create-db database_name")
    end
  end

  context "#rm_command" do
    let(:deployer) { described_class.new(:dummy_env) }

    it "creates a valid shell rm command" do
      expect(deployer.send(:rm_command, "/var/my dump.sql")).to eq("rm /var/my\\ dump.sql")
    end
  end

  context "#mysql_import_command" do
    let(:deployer) { described_class.new(:dummy_env) }

    it "creates a valid mysql import command" do
      command = deployer.send(
        :mysql_import_command,
        "./my dump.sql",
        {
          host: "localhost",
          port: "8888",
          user: "root",
          password: "'\"$ciao",
          charset: "utf8",
          name: "database_name"
        }
      )
      expect(command).to eq("mysql --host=localhost --port=8888 --user=root --password=\\'\\\"\\$ciao --default-character-set=utf8 --database=database_name --execute=SOURCE\\ ./my\\ dump.sql")
    end
  end

  context "#compress_command" do
    let(:deployer) { described_class.new(:dummy_env) }

    it "cerates a valid gzip command" do
      command = deployer.send(
        :compress_command,
        "dummy file.sql"
      )

      expect(command).to eq("gzip --best dummy\\ file.sql")
    end
  end

  context "#uncompress_command" do
    let(:deployer) { described_class.new(:dummy_env) }

    it "cerates a valid gunzip command" do
      command = deployer.send(
        :uncompress_command,
        "dummy file.sql"
      )

      expect(command).to eq("gunzip dummy\\ file.sql")
    end
  end
end
