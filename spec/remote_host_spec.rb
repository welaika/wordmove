require 'hashie'
require 'tempfile'
require 'wordmove/hosts/local_host'
require 'wordmove/hosts/remote_host'
require 'active_support/core_ext'

describe Wordmove::RemoteHost do

  let!(:config) {
    Hashie::Mash.new(YAML::load(File.open(File.join( File.dirname(__FILE__), "fixtures", "Movefile"))))
  }

  let(:host) {
    config.remote[:logger] = stub
    host = Wordmove::RemoteHost.new( config.remote )
    host.stub!(:locally_run).and_return( 1 )
    host
  }

  let(:source_dir) { "foobar" }
  let(:dest_dir) { "barfoo" }
  let(:rsync_command) { "rsync" }
  let(:rsync_flags) { ["-azLKO", "-e"] }

  def rsync_options(ssh_command)
    [
      rsync_command,
      *rsync_flags,
      ssh_command,
      anything(),
      "--delete",
      ":#{source_dir}/",
      dest_dir
    ]
  end

  context ".upload_dir" do
    it "should use config ports, username and password properly" do
      host.should_receive(:locally_run).with(*rsync_options("sshpass -p password ssh -p 30000 username@host"))
      host.upload_dir( source_dir, dest_dir )
    end

    it "should skip port if missing" do
      config.remote!.ssh!.port = nil
      host.should_receive(:locally_run).with(*rsync_options("sshpass -p password ssh username@host"))
      host.upload_dir( source_dir, dest_dir )
    end

    it "should skip username if missing" do
      config.remote!.ssh!.username = nil
      host.should_receive(:locally_run).with(*rsync_options("sshpass -p password ssh -p 30000 host"))
      host.upload_dir( source_dir, dest_dir )
    end

    context "when password is missing" do
      before { config.remote!.ssh!.password = nil }

      it "should use config ports and username properly" do
        host.should_receive(:locally_run).with(*rsync_options("ssh -p 30000 username@host"))
        host.upload_dir( source_dir, dest_dir )
      end

      it "should skip port if missing" do
        config.remote!.ssh!.port = nil
        host.should_receive(:locally_run).with(*rsync_options("ssh username@host"))
        host.upload_dir( source_dir, dest_dir )
      end

      it "should skip username if missing" do
        config.remote!.ssh!.username = nil
        host.should_receive(:locally_run).with(*rsync_options("ssh -p 30000 host"))
        host.upload_dir( source_dir, dest_dir )
      end
    end
  end
end
