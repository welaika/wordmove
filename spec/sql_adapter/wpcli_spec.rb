describe Wordmove::SqlAdapter::Wpcli do
  let(:config_key) { :vhost }
  let(:source_config) { { vhost: 'sausage' } }
  let(:dest_config) { { vhost: 'bacon' } }
  let(:adapter) do
    Wordmove::SqlAdapter::Wpcli.new(
      source_config,
      dest_config,
      config_key
    )
  end

  context "#command" do
    it "returns the right command as a string" do
      expect(adapter.command)
        .to eq("wp search-replace sausage bacon --quiet "\
               "--skip-columns=guid --all-tables --allow-root")
    end
  end
end
