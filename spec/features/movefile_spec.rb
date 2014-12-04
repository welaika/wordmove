require 'spec_helper'
require 'wordmove/generators/movefile'

describe Wordmove::Generators::Movefile do

  let(:movefile) { 'Movefile' }
  let(:tmpdir) { "/tmp/wordmove" }

  before do
    @pwd = Dir.pwd
    FileUtils.mkdir(tmpdir)
    Dir.chdir(tmpdir)
  end

  after do
    Dir.chdir(@pwd)
    FileUtils.rm_rf(tmpdir)
  end

  context "::start" do
    before do
      capture(:stdout) { Wordmove::Generators::Movefile.start }
    end

    it 'creates a Movefile' do
      expect(File.exists?(movefile)).to be true
    end

    it 'fills local wordpress_path using shell path' do
      yaml = YAML::load(File.open(movefile))
      expect(yaml['local']['wordpress_path']).to eq(Dir.pwd)
    end

    it 'fills database configuration defaults' do
      yaml = YAML::load(File.open(movefile))
      expect(yaml['local']['database']['name']).to eq('database_name')
      expect(yaml['local']['database']['user']).to eq('user')
      expect(yaml['local']['database']['password']).to eq('password')
      expect(yaml['local']['database']['host']).to eq('127.0.0.1')
    end
  end

  context "database configuration" do
    let(:wp_config) { File.join(File.dirname(__FILE__), "../fixtures/wp-config.php") }

    before do
      FileUtils.cp(wp_config, ".")
      capture(:stdout) { Wordmove::Generators::Movefile.start }
    end

    it 'fills database configuration from wp-config' do
      yaml = YAML::load(File.open(movefile))
      expect(yaml['local']['database']['name']).to eq('wordmove_db')
      expect(yaml['local']['database']['user']).to eq('wordmove_user')
      expect(yaml['local']['database']['password']).to eq('wordmove_password')
      expect(yaml['local']['database']['host']).to eq('wordmove_host')
    end
  end
end
