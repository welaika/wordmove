require 'wordmove/deployer/base'
require 'tempfile'

describe Wordmove::Deployer::Base do
  let(:klass) { Wordmove::Deployer::Base }

  context "::fetch_movefile" do
    TMPDIR = "/tmp/wordmove"

    let(:path) { File.join(TMPDIR, 'Movefile') }
    let(:yaml) { "name: Waldo\njob: Hider" }

    before do
      FileUtils.mkdir(TMPDIR)
      klass.stub(:current_dir).and_return(TMPDIR)
      klass.stub(:logger).and_return(double('logger').as_null_object)
    end

    after do
      FileUtils.rm_rf(TMPDIR)
    end

    context "when Movefile is missing" do
      it 'raises an exception' do
        expect { klass.fetch_movefile }.to raise_error(StandardError)
      end
    end

    context "when Movefile is present" do
      before do
        File.open(path, 'w') { |f| f.write(yaml) }
      end

      it 'finds a Movefile in current dir' do
        result = klass.fetch_movefile
        expect(result['name']).to eq('Waldo')
        expect(result['job']).to eq('Hider')
      end

      context "when Movefile has extensions" do
        let(:path) { File.join(TMPDIR, 'Movefile.yml') }

        it 'finds it aswell' do
          result = klass.fetch_movefile
          expect(result['name']).to eq('Waldo')
          expect(result['job']).to eq('Hider')
        end
      end

      context "directories traversal" do
        before do
          @test_dir = File.join(TMPDIR, "test")
          FileUtils.mkdir(@test_dir)
          klass.stub(:current_dir).and_return(@test_dir)
        end

        it 'goes up through the directory tree and finds it' do
          result = klass.fetch_movefile
          expect(result['name']).to eq('Waldo')
          expect(result['job']).to eq('Hider')
        end

        context 'Movefile not found, met root node' do
          it 'raises an exception' do
            klass.stub(:current_dir).and_return('/tmp')
            expect { klass.fetch_movefile }.to raise_error(StandardError)
          end
        end

        context 'Movefile not found, found wp-config.php' do
          before do
            FileUtils.touch(File.join(@test_dir, "wp-config.php"))
          end

          it 'raises an exception' do
            expect { klass.fetch_movefile }.to raise_error(StandardError)
          end
        end
      end

    end
  end

end

