require 'spec_helper'

describe Wordmove::WpcliHelpers do
  subject do
    Class.new do
      include Wordmove::WpcliHelpers
    end
  end

  let(:a_context) do
    OrganizerContextFactory.make_for(Wordmove::Actions::AdaptLocalDb, :pull)
  end

  context '.wpcli_config_path' do
    context 'when having wp-cli.yml in wordpress root directory' do
      it 'returns the path configured in YAML file' do
        a_context[:local_options][:wordpress_path] = fixture_folder_root_relative_path

        expect(subject.wpcli_config_path(a_context)).to eq('/path/to/steak')
      end
    end

    context 'when called with a path instead of a config' do
      it 'not finding any path using wpcli it will return the path passed as argument' do
        expect(subject.wpcli_config_path('/path/to/biscuit')).to eq('/path/to/biscuit')
      end
    end

    context 'when there is not wp-cli.yml in wordpress root directory' do
      context 'if wp-cli is configured someway with a custom path' do
        before do
          allow(subject)
            .to receive(:`)
            .with('wp cli param-dump --with-values --allow-root')
            .and_return("{\"path\":{\"current\":\"\/path\/to\/pudding\"}}")
        end

        it 'returns the configured path' do
          expect(subject.wpcli_config_path(a_context)).to eq('/path/to/pudding')
        end

        context 'when called with a path instead of a config' do
          it 'returns the configured path anyway' do
            expect(subject.wpcli_config_path('/path/to/biscuit')).to eq('/path/to/pudding')
          end
        end
      end

      context 'when wp-cli param-dump returns empty string' do
        before do
          allow(subject)
            .to receive(:`)
            .with('wp cli param-dump --with-values --allow-root')
            .and_return('')
        end

        it 'will fallback to movefile config without raising errors' do
          expect { subject.wpcli_config_path(a_context) }.to_not raise_error
          # Would have been JSON::ParserError
        end
      end
    end
  end
end
