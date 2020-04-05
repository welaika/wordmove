describe Wordmove::Logger do
  context '#info' do
    context 'having some string to filter' do
      let(:logger) { described_class.new(STDOUT, ['hidden']) }

      it 'will hide the passed strings' do
        expect { logger.info('What I write is hidden') }
          .to output(/What I write is \[secret\]/)
          .to_stdout_from_any_process
      end
    end

    context 'having a string with regexp special characters' do
      let(:logger) { described_class.new(STDOUT, ['comp/3xPa((w0r]']) }

      it 'will hide the passed strings' do
        expect { logger.info('What I write is comp/3xPa((w0r]') }
          .to output(/What I write is \[secret\]/)
          .to_stdout_from_any_process
      end
    end
  end
end
