describe Wordmove::DefaultSqlAdapter do
  let(:sql_path) { double }
  let(:source_config) { double }
  let(:dest_config) { double }
  let(:adapter) do
    Wordmove::DefaultSqlAdapter.new(
      sql_path,
      source_config,
      dest_config
    )
  end

  context ".initialize" do
    it "should assign variables correctly on initialization" do
      expect(adapter.sql_path).to eq(sql_path)
      expect(adapter.source_config).to eq(source_config)
      expect(adapter.dest_config).to eq(dest_config)
    end
  end

  context ".sql_content" do
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write('DUMP')
        d.close
      end
    end
    let(:sql_path) { sql.path }

    it "should read the sql file content" do
      expect(adapter.sql_content).to eq('DUMP')
    end
  end

  context ".adapt!" do
    it "should replace host, path and write to sql" do
      expect(adapter).to receive(:replace_vhost!).and_return(true)
      expect(adapter).to receive(:replace_wordpress_path!).and_return(true)
      expect(adapter).to receive(:write_sql!).and_return(true)
      adapter.adapt!
    end
  end

  context ".replace_vhost!" do
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write(File.read(fixture_path_for('dump.sql')))
        d.close
      end
    end
    let(:sql_path) { sql.path }

    context "with port" do
      let(:source_config) { { vhost: 'localhost:8080' } }
      let(:dest_config) { { vhost: 'foo.bar:8181' } }

      it "should replace domain and port" do
        adapter.replace_vhost!
        adapter.write_sql!

        expect(File.read(sql)).to match('foo.bar:8181')
        expect(File.read(sql)).to_not match('localhost:8080')
      end
    end

    context "without port" do
      let(:source_config) { { vhost: 'localhost' } }
      let(:dest_config) { { vhost: 'foo.bar' } }

      it "should replace domain leving port unaltered" do
        adapter.replace_vhost!
        adapter.write_sql!

        expect(File.read(sql)).to match('foo.bar:8080')
        expect(File.read(sql)).to_not match('localhost:8080')
      end
    end
  end

  describe "replace single fields" do
    context ".replace_vhost!" do
      let(:source_config) { { vhost: "DUMP" } }
      let(:dest_config)   { { vhost: "FUNK" } }

      it "should replace source vhost with dest vhost" do
        expect(adapter).to receive(:replace_field!).with("DUMP", "FUNK").and_return(true)
        adapter.replace_vhost!
      end
    end

    context ".replace_wordpress_path!" do
      let(:source_config) { { wordpress_path: "DUMP" } }
      let(:dest_config)   { { wordpress_path: "FUNK" } }

      it "should replace source vhost with dest wordpress paths" do
        expect(adapter).to receive(:replace_field!).with("DUMP", "FUNK").and_return(true)
        adapter.replace_wordpress_path!
      end

      context "given an absolute path" do
        let(:source_config) { { wordpress_absolute_path: "ABSOLUTE_DUMP", wordpress_path: "DUMP" } }

        it "should replace the absolute path instead" do
          expect(adapter).to receive(:replace_field!).with("ABSOLUTE_DUMP", "FUNK").and_return(true)
          adapter.replace_wordpress_path!
        end
      end
    end
  end

  context ".replace_field!" do
    it "should replace source vhost with dest vhost" do
      expect(adapter).to receive(:serialized_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      expect(adapter).to receive(:simple_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      adapter.replace_field!("DUMP", "FUNK")
    end
  end

  context ".serialized_replace!" do
    let(:content) do
      'a:3:{i:0;s:20:"http://dump.com/spam";i:1;s:6:"foobar";i:2;s:22:"http://dump.com/foobar";}'
    end
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write(content)
        d.close
      end
    end
    let(:sql_path) { sql.path }

    it "should replace source vhost with dest vhost" do
      adapter.serialized_replace!('http://dump.com', 'http://shrubbery.com')
      expect(adapter.sql_content).to eq(
        [
          'a:3:{i:0;s:25:"http://shrubbery.com/spam";i:1;s:6:"foobar";',
          'i:2;s:27:"http://shrubbery.com/foobar";}'
        ].join
      )
    end

    context "given empty strings" do
      let(:content) { 's:0:"";s:3:"foo";s:0:"";' }

      it "should leave them untouched" do
        adapter.serialized_replace!('foo', 'sausage')
        expect(adapter.sql_content).to eq('s:0:"";s:7:"sausage";s:0:"";')
      end

      context "considering escaping" do
        let(:content) { 's:0:\"\";s:3:\"foo\";s:0:\"\";' }

        it "should leave them untouched" do
          adapter.serialized_replace!('foo', 'sausage')
          expect(adapter.sql_content).to eq('s:0:\"\";s:7:\"sausage\";s:0:\"\";')
        end
      end
    end

    context "given strings with escaped content" do
      let(:content) { 's:6:"dump\"\"";' }

      it "should calculate the correct final length" do
        adapter.serialized_replace!('dump', 'sausage')
        expect(adapter.sql_content).to eq('s:9:"sausage\"\"";')
      end
    end

    context "given multiple types of string quoting" do
      let(:content) do
        [
          "a:3:{s:20:\\\"http://dump.com/spam\\\";s:6:'foobar';",
          "s:22:'http://dump.com/foobar';s:8:'sausages';}"
        ].join
      end

      it "should handle replacing just as well" do
        adapter.serialized_replace!('http://dump.com', 'http://shrubbery.com')
        expect(adapter.sql_content).to eq(
          [
            "a:3:{s:25:\\\"http://shrubbery.com/spam\\\";s:6:'foobar';",
            "s:27:'http://shrubbery.com/foobar';s:8:'sausages';}"
          ].join
        )
      end
    end

    context "given multiple occurences in the same string" do
      let(:content) { 'a:1:{i:0;s:52:"ni http://dump.com/spam ni http://dump.com/foobar ni";}' }

      it "should replace all occurences" do
        adapter.serialized_replace!('http://dump.com', 'http://shrubbery.com')
        expect(adapter.sql_content).to eq(
          'a:1:{i:0;s:62:"ni http://shrubbery.com/spam ni http://shrubbery.com/foobar ni";}'
        )
      end
    end
  end

  context ".simple_replace!" do
    let(:content) { "THE DUMP!" }
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write(content)
        d.close
      end
    end
    let(:sql_path) { sql.path }

    it "should replace source vhost with dest vhost" do
      adapter.simple_replace!("DUMP", "FUNK")
      expect(adapter.sql_content).to eq("THE FUNK!")
    end
  end

  context ".write_sql!" do
    let(:content) { "THE DUMP!" }
    let(:sql) do
      Tempfile.new('sql').tap do |d|
        d.write(content)
        d.close
      end
    end
    let(:sql_path) { sql.path }
    let(:the_funk) { "THE FUNK THE FUNK THE FUNK" }

    it "should write content to file" do
      adapter.sql_content = the_funk
      adapter.write_sql!
      File.open(sql_path).read == the_funk
    end
  end
end
