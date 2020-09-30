require 'spec_helper'

describe Wordmove::CLI do
  let(:cli) { described_class.new }
  let(:options) { {} }

  context '#init' do
    it 'delagates the command to the Movefile Generator' do
      expect(Wordmove::Generators::Movefile).to receive(:start)
      cli.invoke(:init, [], options)
    end
  end

  context '#doctor' do
    it 'delagates the command to Doctor class' do
      expect(Wordmove::Doctor).to receive(:start)
      cli.invoke(:doctor, [], options)
    end
  end

  context '#pull' do
    context 'without a movefile' do
      it 'it rescues from a MovefileNotFound exception' do
        expect { cli.invoke(:pull, []) }.to raise_error SystemExit
      end
    end
  end

  context '#list' do
    subject do
      silence_stream($stdout) do
        cli.invoke(:list, [])
      end
    end
    let(:list_class) { Wordmove::EnvironmentsList }
    # Werdmove::EnvironmentsList.print should be called
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
                  "found character that cannot start any token",
                  "while scanning for the next token"]
          allow(list_class).to receive(:print).and_raise(Psych::SyntaxError.new(*args))
        end

        it { expect { subject }.to raise_error SystemExit }
      end
    end

    context 'with a movefile' do
      subject { cli.invoke(:list, [], options) }
      let(:options) { { config: movefile_path_for('Movefile') } }
      it 'invoke list without error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  context '#push' do
    context 'without a movefile' do
      it 'it rescues from a MovefileNotFound exception' do
        expect { cli.invoke(:pull, []) }.to raise_error SystemExit
      end
    end
  end

  context '--all' do
    let(:options) { { all: true, config: movefile_path_for('Movefile') } }
    let(:ordered_components) { %i[wordpress uploads themes plugins mu_plugins languages db] }
  end
end
