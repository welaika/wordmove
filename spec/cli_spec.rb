require 'spec_helper'

describe Wordmove::CLI do
  let(:cli) { Dry::CLI.new(Wordmove::CLI::Commands) }
  let(:options) { {} }

  context '#init' do
    it 'delagates the command to the Movefile Generator' do
      expect(Wordmove::Generators::Movefile).to receive(:generate)

      silence_stream($stdout) do
        cli.call(arguments: %w[init])
      end
    end
  end

  context '#doctor' do
    it 'delagates the command to Doctor class' do
      expect(Wordmove::Doctor).to receive(:start)
      cli.call(arguments: %w[doctor])
    end
  end

  context '#pull' do
    context 'without a movefile' do
      it 'it rescues from a MovefileNotFound exception' do
        expect { cli.call(arguments: %w[pull]) }.to raise_error SystemExit
      end
    end
  end

  context '#list' do
    subject do
      silence_stream($stdout) do
        cli.call(arguments: %w[list])
      end
    end
    let(:list_class) { Wordmove::EnvironmentsList }

    it 'delagates the command to EnvironmentsList class' do
      expect(list_class).to receive(:print)
      subject
    end

    context 'without a valid movefile' do
      context 'no movefile' do
        it { expect { subject }.to raise_error SystemExit }
      end

      context 'syntax error movefile ' do
        before do
          # Ref. https://github.com/ruby/psych/blob/master/lib/psych/syntax_error.rb#L8
          # Arguments for initialization: file, line, col, offset, problem, context
          args = [nil, 1, 5, 0,
                  'found character that cannot start any token',
                  'while scanning for the next token']
          allow(list_class).to receive(:print).and_raise(Psych::SyntaxError.new(*args))
        end

        it { expect { subject }.to raise_error SystemExit }
      end
    end

    context 'with a movefile' do
      let(:options) { { config: movefile_path_for('Movefile') } }
      subject { cli.call(arguments: ['list', "--config=#{movefile_path_for('Movefile')}"]) }

      it 'invoke list without error' do
        silence_stream($stdout) do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  context '#push' do
    context 'without a movefile' do
      it 'it rescues from a MovefileNotFound exception' do
        expect { cli.call(arguments: %w[push]) }.to raise_error SystemExit
      end
    end
  end

  context '--all' do
    let(:options) { { all: true, config: movefile_path_for('Movefile') } }
    let(:ordered_components) { %i[wordpress uploads themes plugins mu_plugins languages db] }
  end
end
