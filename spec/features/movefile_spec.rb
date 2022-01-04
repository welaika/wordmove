describe Wordmove::Generators::Movefile do
  let(:movefile) { 'movefile.yml' }
  let(:tmpdir) { '/tmp/wordmove' }

  before do
    @pwd = Dir.pwd
    FileUtils.mkdir(tmpdir)
    Dir.chdir(tmpdir)
  end

  after do
    Dir.chdir(@pwd)
    FileUtils.rm_rf(tmpdir)
  end

  context '::start' do
    before do
      silence_stream($stdout) { Wordmove::Generators::Movefile.generate }
    end

    it 'creates a Movefile' do
      expect(File.exist?(movefile)).to be true
    end

    it 'fills local wordpress_path using shell path' do
      yaml = YAML.safe_load(ERB.new(File.read(movefile)).result)
      expect(yaml['local']['wordpress_path']).to eq(Dir.pwd)
    end

    it 'creates a Movifile having a "global.sql_adapter" key' do
      yaml = YAML.safe_load(ERB.new(File.read(movefile)).result)
      expect(yaml['global']).to be_present
      expect(yaml['global']['sql_adapter']).to be_present
      expect(yaml['global']['sql_adapter']).to eq('wpcli')
    end
  end
end
