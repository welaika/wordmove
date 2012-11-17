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

  context ".replace_vhost!" do
    it "should replace source vhost with dest vhost" do
      sql_mover.should_receive(:replace_field!).with(:vhost).and_return(true)
      sql_mover.replace_vhost!
    end
  end

  context ".replace_wordpress_path!" do
    it "should replace source path with dest path" do
      sql_mover.should_receive(:replace_field!).with(:wordpress_path).and_return(true)
      sql_mover.replace_wordpress_path!
    end
  end

  context ".replace_field!" do
    let(:source_config) { stub(:field => "DUMP") }
    let(:dest_config) { stub(:field => "FUNK") }

    it "should replace source vhost with dest vhost" do
      sql_mover.should_receive(:serialized_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      sql_mover.should_receive(:simple_replace!).ordered.with("DUMP", "FUNK").and_return(true)
      sql_mover.replace_field!(:field)
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
