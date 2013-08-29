require 'wordmove/deployer/base'
require 'tempfile'

describe Wordmove::Deployer::Base do
  let(:klass) { Wordmove::Deployer::Base }

  context "::fetch_movefile" do
    let(:name) { 'Movefile' }
    let(:path) { File.join(TMPDIR, name) }
    let(:yaml) { "name: Waldo\njob: Hider" }

    TMPDIR = "/tmp/wordmove"

    before do
      FileUtils.mkdir(TMPDIR)
      klass.stub(:movefile_dir).and_return(TMPDIR)
    end

    after do
      FileUtils.rm_rf(TMPDIR)
    end

    context "when Movefile is missing" do
      it 'raises an exception' do
        expect { klass.fetch_movefile(name) }.to raise_error(StandardError)
      end
    end

    context "when Movefile is present" do
      before do
        File.open(path, 'w') { |f| f.write(yaml) }
      end

      it 'finds a Movefile in current dir' do
        result = klass.fetch_movefile(name)
        expect(result['name']).to eq('Waldo')
        expect(result['job']).to eq('Hider')
      end

      context "when Movefile has extensions" do
        let(:path) { File.join(TMPDIR, 'Movefile.yml') }

        it 'finds it aswell' do
          result = klass.fetch_movefile(name)
          expect(result['name']).to eq('Waldo')
          expect(result['job']).to eq('Hider')
        end
      end
    end
  end

end

