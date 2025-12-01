describe WordpressDirectory do
  it 'is defined' do
    expect(Object.const_defined?('WordpressDirectory')).to be true
  end

  it 'has DEAFAULT_PATHS defined' do
    expect(described_class::DEFAULT_PATHS).to be_an_instance_of Hash
    expect(described_class::DEFAULT_PATHS).to eq(
      WordpressDirectory::Path::WP_CONTENT => 'wp-content',
      WordpressDirectory::Path::WP_CONFIG => 'wp-config.php',
      WordpressDirectory::Path::PLUGINS => 'wp-content/plugins',
      WordpressDirectory::Path::MU_PLUGINS => 'wp-content/mu-plugins',
      WordpressDirectory::Path::THEMES => 'wp-content/themes',
      WordpressDirectory::Path::UPLOADS => 'wp-content/uploads',
      WordpressDirectory::Path::LANGUAGES => 'wp-content/languages'
    )
  end

  context '.default_path_for' do
    context 'given a symbol :wp_config' do
      it 'returns the wp-config.php default path' do
        expect(described_class.default_path_for(:wp_config)).to eq 'wp-config.php'
      end
    end
  end

  context '.path' do
    let(:movefile) { Wordmove::Movefile.new({ config: movefile_path_for('Movefile') }, nil, false) }
    let(:options) { movefile.options[:local] }

    context 'given an additional path as a string' do
      it 'returns the absolute path of the folder joined with the additional one' do
        wd = described_class.new(:uploads, options)
        expect(wd.path('pirate')).to eq('~/dev/sites/your_site/wp-content/uploads/pirate')
      end
    end

    context 'without arguments' do
      it 'returns the absolute path for the required folder' do
        wd = described_class.new(:uploads, options)
        expect(wd.path).to eq('~/dev/sites/your_site/wp-content/uploads')
      end
    end
  end

  context '.url' do
    let(:movefile) { Wordmove::Movefile.new({ config: movefile_path_for('Movefile') }, nil, false) }
    let(:options) { movefile.options[:local] }

    context 'given an additional path as a string' do
      it 'returns the URL of the folder joined with the additional path' do
        wd = described_class.new(:uploads, options)
        expect(wd.url('pirate.png')).to eq('http://vhost.local/wp-content/uploads/pirate.png')
      end
    end

    context 'without arguments' do
      it 'returns the URL for the required folder' do
        wd = described_class.new(:uploads, options)
        expect(wd.url).to eq('http://vhost.local/wp-content/uploads')
      end
    end
  end

  context '.relative_path' do
    context 'given a movefile with custom paths defined' do
      let(:movefile) do
        Wordmove::Movefile.new({ config: movefile_path_for('custom_paths') }, nil, false)
      end
      let(:options) { movefile.options[:remote] }

      context 'given addional path as argument' do
        it 'returns the customized relative path joined with the additional one' do
          wd = described_class.new(:uploads, options)
          expect(wd.relative_path('additional')).to eq('wp-content/pirate/additional')
        end
      end
    end
  end
end
