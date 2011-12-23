require 'spec_helper'

describe Wordmove::RemoteHost do

  let!(:config) {
    Hashie::Mash.new(YAML::load(File.open(File.join( File.dirname(__FILE__), "fixtures", "Movefile"))))
  }

  let(:host) {
    logger = Wordmove::Logger.new
    logger.level = Logger::INFO
    config.remote[:logger] = @logger
    host = Wordmove::RemoteHost.new( config.remote )
    host.stub!(:locally_run).and_return( 1 )
    host
  }

  context ".upload_dir" do

    it "should use config ports, username and password properly" do
      host.should_receive(:locally_run).with("rsync", "-azLK", "-e",  "sshpass -p password ssh -p 30000", anything(), "--delete", "username@host:foobar/", "barfoo" )
      host.upload_dir( "foobar", "barfoo" )
    end

    it "should skip port if missing" do
      config.remote!.ssh!.port = nil
      host.should_receive(:locally_run).with("rsync", "-azLK", "-e",  "sshpass -p password ssh", anything(), "--delete", "username@host:foobar/", "barfoo" )
      host.upload_dir( "foobar", "barfoo" )
    end

    it "should skip username if missing" do
      config.remote!.ssh!.username = nil
      host.should_receive(:locally_run).with("rsync", "-azLK", "-e",  "sshpass -p password ssh -p 30000", anything(), "--delete", "host:foobar/", "barfoo" )
      host.upload_dir( "foobar", "barfoo" )
    end

    context "when password is missing" do

      before { config.remote!.ssh!.password = nil }

      it "should use config ports and username properly" do
        host.should_receive(:locally_run).with("rsync", "-azLK", "-e",  "ssh -p 30000", anything(), "--delete", "username@host:foobar/", "barfoo" )
        host.upload_dir( "foobar", "barfoo" )
      end

      it "should skip port if missing" do
        config.remote!.ssh!.port = nil
        host.should_receive(:locally_run).with("rsync", "-azLK", anything(), "--delete", "username@host:foobar/", "barfoo" )
        host.upload_dir( "foobar", "barfoo" )
      end

      it "should skip username if missing" do
        config.remote!.ssh!.username = nil
        host.should_receive(:locally_run).with("rsync", "-azLK", "-e",  "ssh -p 30000", anything(), "--delete", "host:foobar/", "barfoo" )
        host.upload_dir( "foobar", "barfoo" )
      end

    end

  end

end
