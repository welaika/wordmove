require 'spec_helper'

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

  before do
    allow(adapter).to receive(:wp_in_path?).and_return(true)
    allow(adapter)
      .to receive(:`)
      .with('wp cli param-dump --with-values')
      .and_return("{}")
  end

  context "#command" do
    context "having wp-cli.yml in local_path" do
      let(:local_path) { fixture_folder_root_relative_path }

      it "returns the right command as a string" do
        expect(adapter.command)
          .to eq("wp search-replace --path=/path/to/steak sausage bacon --quiet "\
                "--skip-columns=guid --all-tables --allow-root")
      end
    end

    context "without wp-cli.yml in local_path" do
      before do
        allow(adapter)
          .to receive(:`)
          .with('wp cli param-dump --with-values')
          .and_return("{\"path\":{\"current\":\"\/path\/to\/pudding\"}}")
      end
      context "but still reachable by wp-cli" do
        it "returns the right command as a string" do
          expect(adapter.command)
            .to eq("wp search-replace --path=/path/to/pudding sausage bacon --quiet "\
                  "--skip-columns=guid --all-tables --allow-root")
        end
      end
    end

    context "without any wp-cli configuration" do
      it "returns the right command with '--path' flag set to local_path" do
        expect(adapter.command)
          .to eq("wp search-replace --path=/path/to/ham sausage bacon --quiet "\
                 "--skip-columns=guid --all-tables --allow-root")
      end
    end
  end
end
