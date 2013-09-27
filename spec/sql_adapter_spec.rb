require 'wordmove/sql_adapter'
require 'tempfile'

describe Wordmove::SqlAdapter do

  let(:sql_path) { double }
  let(:source_config) { double }
  let(:dest_config) { double }
  let(:adapter) {
    Wordmove::SqlAdapter.new(
      sql_path,
      source_config,
      dest_config
    )
  }

  context ".initialize" do
    it "should assign variables correctly on initialization" do
      adapter.sql_path.should == sql_path
      adapter.source_config.should == source_config
      adapter.dest_config.should == dest_config
    end
  end

  context ".sql_content" do
    let(:sql) do
      Tempfile.new('sql').tap { |d| d.write('DUMP'); d.close }
    end
    let(:sql_path) { sql.path }

    it "should read the sql file content" do
      adapter.sql_content.should == 'DUMP'
    end
  end

  context ".adapt!" do
    it "should replace host, path and write to sql" do
      adapter.should_receive(:replace_vhost!).and_return(true)
      adapter.should_receive(:replace_wordpress_path!).and_return(true)
      adapter.should_receive(:write_sql!).and_return(true)
      adapter.adapt!
    end
  end

  describe "replace single fields" do
    context ".replace_vhost!" do
      let(:source_config) do { :vhost => "DUMP" } end
      let(:dest_config)   do { :vhost => "FUNK" } end

      it "should replace source vhost with dest vhost" do
        adapter.should_receive(:replace_field!).with("DUMP", "FUNK").and_return(true)
        adapter.replace_vhost!
      end
    end

    context ".replace_wordpress_path!" do
      let(:source_config) do { :wordpress_path => "DUMP" } end
      let(:dest_config)   do { :wordpress_path => "FUNK" } end

      it "should replace source vhost with dest wordpress paths" do
        adapter.should_receive(:replace_field!).with("DUMP", "FUNK").and_return(true)
        adapter.replace_wordpress_path!
      end

      context "given an absolute path" do
        let(:source_config) do { :wordpress_absolute_path => "ABSOLUTE_DUMP", :wordpress_path => "DUMP" } end

        it "should replace the absolute path instead" do
          adapter.should_receive(:replace_field!).with("ABSOLUTE_DUMP", "FUNK").and_return(true)
          adapter.replace_wordpress_path!
        end
      end
    end
  end

  context ".replace_field!" do
    it "should replace source vhost with dest vhost" do
      adapter.should_receive(:serialized_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      adapter.should_receive(:simple_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      adapter.replace_field!("DUMP", "FUNK")
    end
  end

  context ".serialized_replace!" do
    let(:content) { 'a:3:{i:0;s:20:"http://dump.com/spam";i:1;s:6:"foobar";i:2;s:22:"http://dump.com/foobar";}' }
    let(:sql) { Tempfile.new('sql').tap do |d| d.write(content); d.close end }
    let(:sql_path) { sql.path }

    it "should replace source vhost with dest vhost" do
      adapter.serialized_replace!('http://dump.com', 'http://shrubbery.com')
      adapter.sql_content.should == 'a:3:{i:0;s:25:"http://shrubbery.com/spam";i:1;s:6:"foobar";i:2;s:27:"http://shrubbery.com/foobar";}'
    end

    context "given empty strings" do
      let(:content) { 's:0:"";s:3:"foo";s:0:"";' }

      it "should leave them untouched" do
        adapter.serialized_replace!('foo', 'sausage')
        adapter.sql_content.should == 's:0:"";s:7:"sausage";s:0:"";'
      end

      context "considering escaping" do
        let(:content) { 's:0:\"\";s:3:\"foo\";s:0:\"\";' }

        it "should leave them untouched" do
          adapter.serialized_replace!('foo', 'sausage')
          adapter.sql_content.should == 's:0:\"\";s:7:\"sausage\";s:0:\"\";'
        end
      end
    end

    context "given strings with escaped content" do
      let(:content) { 's:6:"dump\"\"";' }

      it "should calculate the correct final length" do
        adapter.serialized_replace!('dump', 'sausage')
        adapter.sql_content.should == 's:9:"sausage\"\"";'
      end
    end

    context "given multiple types of string quoting" do
      let(:content) { "a:3:{s:20:\\\"http://dump.com/spam\\\";s:6:'foobar';s:22:'http://dump.com/foobar';s:8:'sausages';}" }

      it "should handle replacing just as well" do
        adapter.serialized_replace!('http://dump.com', 'http://shrubbery.com')
        adapter.sql_content.should == "a:3:{s:25:\\\"http://shrubbery.com/spam\\\";s:6:'foobar';s:27:'http://shrubbery.com/foobar';s:8:'sausages';}"
      end
    end

    context "given multiple occurences in the same string" do
      let(:content) { 'a:1:{i:0;s:52:"ni http://dump.com/spam ni http://dump.com/foobar ni";}' }

      it "should replace all occurences" do
        adapter.serialized_replace!('http://dump.com', 'http://shrubbery.com')
        adapter.sql_content.should == 'a:1:{i:0;s:62:"ni http://shrubbery.com/spam ni http://shrubbery.com/foobar ni";}'
      end
    end
  end

  context ".simple_replace!" do
    let(:content) { "THE DUMP!" }
    let(:sql) { Tempfile.new('sql').tap do |d| d.write(content); d.close end }
    let(:sql_path) { sql.path }

    it "should replace source vhost with dest vhost" do
      adapter.simple_replace!("DUMP", "FUNK")
      adapter.sql_content.should == "THE FUNK!"
    end
  end

  context ".write_sql!" do
    let(:content) { "THE DUMP!" }
    let(:sql) { Tempfile.new('sql').tap do |d| d.write(content); d.close end }
    let(:sql_path) { sql.path }
    let(:the_funk) { "THE FUNK THE FUNK THE FUNK" }

    it "should write content to file" do
      adapter.sql_content = the_funk
      adapter.write_sql!
      File.open(sql_path).read == the_funk
    end
  end
end
