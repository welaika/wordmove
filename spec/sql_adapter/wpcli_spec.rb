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
      allow(File).to receive(:exist?).and_return(true)
      allow(YAML).to receive(:load_file).and_return(path: "/path/to/steak")
    end

    it "returns the right command as a string" do
      expect(adapter.command)
        .to eq("wp search-replace --path=/path/to/steak sausage bacon --quiet "\
               "--skip-columns=guid --all-tables --allow-root")
    end
  end

  context "#command_with_params" do
    before do
      allow(adapter).to receive(:wp_in_path?).and_return(true)
      allow(adapter).to receive(:`).and_return("{\"path\":{\"current\":\"\/path\/to\/pudding\"}}")
    end

    it "returns the right command as a string" do
      expect(adapter.command)
        .to eq("wp search-replace --path=/path/to/pudding sausage bacon --quiet "\
               "--skip-columns=guid --all-tables --allow-root")
    end
  end

  context "#command_with_no_configured_path" do
    before do
      allow(adapter).to receive(:wp_in_path?).and_return(true)
      allow(File).to receive(:exist?).and_return(false)
      allow(adapter).to receive(:`).and_return("{}")
    end

    it "returns the right command as a string" do
      expect(adapter.command)
        .to eq("wp search-replace --path=/path/to/ham sausage bacon --quiet "\
               "--skip-columns=guid --all-tables --allow-root")
    end
  end
end
