require 'spec_helper'

describe Wordmove::RemoteHost do

  def load_config( config_path )
    @config = Hashie::Mash.new(YAML::load(File.open(config_path)))
    @logger = Wordmove::Logger.new
    @logger.level = Logger::INFO
    @config.remote[:logger] = @logger
    @host = Wordmove::RemoteHost.new( @config.remote )
    @host.stub!(:locally_run).and_return( 1 )
  end

  it "should use ports properly" do
    load_config( File.join( File.dirname(__FILE__), "fixtures", "Movefile.port" ) )
    @host.should_receive(:locally_run).with("rsync", "-azLK", "-e",  "ssh -p 30000", anything(), anything(), "--delete", "username@host:foobar/", "barfoo" )
    @host.upload_dir("foobar", "barfoo" )
  end

  it "should not use ports if missing" do
    load_config( File.join( File.dirname(__FILE__), "fixtures", "Movefile.no_port" ) )
    @host.should_receive(:locally_run).with("rsync", "-azLK", anything(), anything(), "--delete", "username@host:foobar/", "barfoo" )
    @host.upload_dir("foobar", "barfoo" )
  end

  it "should skip password files when not using passwords" do
    load_config( File.join( File.dirname(__FILE__), "fixtures", "Movefile.no_password" ) )
    @host.should_receive(:locally_run).with("rsync", "-azLK", anything(), "--delete", "username@host:foobar/", "barfoo" )
    @host.upload_dir("foobar", "barfoo" )
  end

  it "should have a password file when using passwords" do
    load_config( File.join( File.dirname(__FILE__), "fixtures", "Movefile.with_password" ) )
    @host.should_receive(:locally_run).with("rsync", "-azLK", /--password-file.*/, anything(), "--delete", "username@host:foobar/", "barfoo" )
    @host.upload_dir("foobar", "barfoo" )
  end
end
