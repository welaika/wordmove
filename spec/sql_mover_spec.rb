require 'wordmove/sql_mover'
require 'tempfile'

describe Wordmove::SqlMover do

  let(:sql_path) { stub }
  let(:source_config) { stub }
  let(:dest_config) { stub }
  let(:sql_mover) {
    Wordmove::SqlMover.new(
      sql_path,
      source_config,
      dest_config
    )
  }

  context ".initialize" do
    it "should assign variables correctly on initialization" do
      sql_mover.sql_path.should == sql_path
      sql_mover.source_config.should == source_config
      sql_mover.dest_config.should == dest_config
    end
  end

  context ".sql_content" do
    let(:sql) do
      Tempfile.new('sql').tap { |d| d.write('DUMP'); d.close }
    end
    let(:sql_path) { sql.path }

    it "should read the sql file content" do
      sql_mover.sql_content.should == 'DUMP'
    end
  end

  context ".move!" do
    it "should replace host, path and write to sql" do
      sql_mover.should_receive(:replace_vhost!).and_return(true)
      sql_mover.should_receive(:replace_wordpress_path!).and_return(true)
      sql_mover.should_receive(:write_sql!).and_return(true)
      sql_mover.move!
    end
  end

  describe "replace single fields" do
    context ".replace_vhost!" do
      let(:source_config) do { :vhost => "DUMP" } end
      let(:dest_config)   do { :vhost => "FUNK" } end

      it "should replace source vhost with dest vhost" do
        sql_mover.should_receive(:replace_field!).with("DUMP", "FUNK").and_return(true)
        sql_mover.replace_vhost!
      end
    end

    context ".replace_wordpress_path!" do
      let(:source_config) do { :wordpress_path => "DUMP" } end
      let(:dest_config)   do { :wordpress_path => "FUNK" } end

      it "should replace source vhost with dest wordpress paths" do
        sql_mover.should_receive(:replace_field!).with("DUMP", "FUNK").and_return(true)
        sql_mover.replace_wordpress_path!
      end

      context "given an absolute path" do
        let(:source_config) do { :wordpress_absolute_path => "ABSOLUTE_DUMP", :wordpress_path => "DUMP" } end

        it "should replace the absolute path instead" do
          sql_mover.should_receive(:replace_field!).with("ABSOLUTE_DUMP", "FUNK").and_return(true)
          sql_mover.replace_wordpress_path!
        end
      end
    end
  end

  context ".replace_field!" do
    it "should replace source vhost with dest vhost" do
      sql_mover.should_receive(:serialized_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      sql_mover.should_receive(:simple_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      sql_mover.replace_field!("DUMP", "FUNK")
    end
  end

  context ".serialized_replace!" do
    let(:content) { 's:4:"spam";s:20:"http://dump.com/spam";s:6:"foobar";s:22:"http://dump.com/foobar";s:8:"sausages"' }
    let(:sql) { Tempfile.new('sql').tap do |d| d.write(content); d.close end }
    let(:sql_path) { sql.path }

    it "should replace source vhost with dest vhost" do
      sql_mover.serialized_replace!('http://dump.com', 'http://shrubbery.com')
      sql_mover.sql_content.should == 's:4:"spam";s:25:"http://shrubbery.com/spam";s:6:"foobar";s:27:"http://shrubbery.com/foobar";s:8:"sausages"'
    end

    context "given multiple types of string quoting" do
      let(:content) { "s:20:\\\"http://dump.com/spam\\\";s:6:'foobar';s:22:'http://dump.com/foobar';s:8:'sausages'" }

      it "handles replacing just as well" do
        sql_mover.serialized_replace!('http://dump.com', 'http://shrubbery.com')
        sql_mover.sql_content.should == "s:25:\\\"http://shrubbery.com/spam\\\";s:6:'foobar';s:27:'http://shrubbery.com/foobar';s:8:'sausages'"
      end
    end
  end

  context ".simple_replace!" do
    let(:content) { "THE DUMP!" }
    let(:sql) { Tempfile.new('sql').tap do |d| d.write(content); d.close end }
    let(:sql_path) { sql.path }

    it "should replace source vhost with dest vhost" do
      sql_mover.simple_replace!("DUMP", "FUNK")
      sql_mover.sql_content.should == "THE FUNK!"
    end
  end

  context ".write_sql!" do
    let(:content) { "THE DUMP!" }
    let(:sql) { Tempfile.new('sql').tap do |d| d.write(content); d.close end }
    let(:sql_path) { sql.path }
    let(:the_funk) { "THE FUNK THE FUNK THE FUNK" }

    it "should write content to file" do
      sql_mover.sql_content = the_funk
      sql_mover.write_sql!
      File.open(sql_path).read == the_funk
    end
  end
end
