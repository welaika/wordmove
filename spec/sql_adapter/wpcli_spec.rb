describe Wordmove::SqlAdapter::Wpcli do
  let(:config_key) { :vhost }
  let(:source_config) { { vhost: 'sausage' } }
  let(:dest_config) { { vhost: 'bacon' } }
  let(:local_path) { '/path/to/ham' }
  let(:adapter) do
    Wordmove::SqlAdapter::Wpcli.new(
      source_config,
      dest_config,
      config_key,
      local_path
    )
  end

  context "#command_with_wp-cli.yml" do
    before do
      allow(adapter).to receive(:wp_in_path?).and_return(true)
      allow(adapter).to receive(:cli_config_exists?).and_return(true)
    end

    it "returns the right command as a string" do
      expect(adapter.command)
        .to eq("wp search-replace sausage bacon --quiet "\
               "--skip-columns=guid --all-tables --allow-root")
    end
  end

  context "#command_without_wp-cli.yml" do
    before do
      allow(adapter).to receive(:wp_in_path?).and_return(true)
      allow(adapter).to receive(:cli_config_exists?).and_return(false)
    end

    it "returns the right command as a string" do
      expect(adapter.command)
        .to eq("wp search-replace --path=/path/to/ham sausage bacon --quiet "\
           "--skip-columns=guid --all-tables --allow-root")
    end
  end
end
