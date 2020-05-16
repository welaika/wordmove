describe Wordmove::Deployer::Base do
  let(:options) do
    { config: movefile_path_for("multi_environments") }
  end
  context ".deployer_for" do
    context "with more then one environment, but none chosen" do
      it "raises an exception" do
        expect { described_class.deployer_for(options) }
          .to raise_exception(Wordmove::UndefinedEnvironment)
      end
    end

    context "with more then one environment, but invalid chosen" do
      it "raises an exception" do
        options[:environment] = "doesnotexist"
        options[:simulate] = true

        expect { described_class.deployer_for(options) }
          .to raise_exception(Wordmove::UndefinedEnvironment)
      end
    end

    context "with ftp remote connection" do
      it "returns an instance of FTP deployer" do
        options[:environment] = "production"
        expect(described_class.deployer_for(options)).to be_a Wordmove::Deployer::FTP
      end
    end

    context "with ssh remote connection" do
      before do
        options[:environment] = "staging"
      end

      it "returns an instance of Ssh::Default deployer" do
        expect(described_class.deployer_for(options))
          .to be_a Wordmove::Deployer::Ssh::DefaultSqlAdapter
      end

      context "when Movefile is configured with 'wpcli' sql_adapter" do
        it "returns an instance of Ssh::WpcliSqlAdapter deployer" do
          options[:config] = movefile_path_for('multi_environments_wpcli_sql_adapter')

          expect(described_class.deployer_for(options))
            .to be_a Wordmove::Deployer::Ssh::WpcliSqlAdapter
        end
      end

      context "with --simulate" do
        it "rsync_options will contain --dry-run" do
          options[:environment] = "staging"
          options[:simulate] = true
          copier = double(:copier)

          allow(copier).to receive(:logger=)

          expect(Photocopier::SSH).to receive(:new)
            .with(hash_including(rsync_options: '--dry-run'))
            .and_return(copier)

          described_class.deployer_for(options)
        end
      end
    end

    context "with unknown type of connection " do
      it "raises an exception" do
        options[:environment] = "missing_protocol"
        expect { described_class.deployer_for(options) }.to raise_error(Wordmove::NoAdapterFound)
      end
    end
  end

  context "#mysql_dump_command" do
    let(:deployer) { described_class.new(:dummy_env, options) }

    it "creates a valid mysqldump command" do
      command = deployer.send(
        :mysql_dump_command,
        {
          host: "localhost",
          port: "8888",
          user: "root",
          password: "'\"$ciao",
          name: "database_name",
          mysqldump_options: "--max_allowed_packet=1G --no-create-db"
        },
        "./mysql dump.sql"
      )

      expect(command).to eq(
        [
          "mysqldump --host=localhost",
          "--port=8888 --user=root --password=\\'\\\"\\$ciao",
          "--result-file=\"./mysql dump.sql\"",
          "--max_allowed_packet=1G --no-create-db database_name"
        ].join(' ')
      )
    end
  end

  context "#mysql_import_command" do
    let(:deployer) { described_class.new(:dummy_env, options) }

    it "creates a valid mysql import command" do
      command = deployer.send(
        :mysql_import_command,
        "./my dump.sql",
        host: "localhost",
        port: "8888",
        user: "root",
        password: "'\"$ciao",
        name: "database_name",
        mysql_options: "--protocol=TCP"
      )
      expect(command).to eq(
        [
          "mysql --host=localhost --port=8888 --user=root",
          "--password=\\'\\\"\\$ciao",
          "--database=database_name",
          "--protocol=TCP",
          "--execute=\"SET autocommit=0;SOURCE ./my dump.sql;COMMIT\""
        ].join(" ")
      )
    end
  end

  context "#compress_command" do
    let(:deployer) { described_class.new(:dummy_env, options) }

    it "cerates a valid gzip command" do
      command = deployer.send(
        :compress_command,
        "dummy file.sql"
      )

      expect(command).to eq("gzip -9 -f \"dummy file.sql\"")
    end
  end

  context "#uncompress_command" do
    let(:deployer) { described_class.new(:dummy_env, options) }

    it "creates a valid gunzip command" do
      command = deployer.send(
        :uncompress_command,
        "dummy file.sql"
      )

      expect(command).to eq("gzip -d -f \"dummy file.sql\"")
    end
  end
end
