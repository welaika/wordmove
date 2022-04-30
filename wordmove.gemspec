lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wordmove/version'

Gem::Specification.new do |spec|
  spec.name          = 'wordmove'
  spec.version       = Wordmove::VERSION
  spec.metadata      = { 'rubygems_mfa_required' => 'true' }
  spec.authors       = [
    'Stefano Verna', 'Ju Liu', 'Fabrizio Monti', 'Alessandro Fazzi', 'Filippo Gangi Dino'
  ]
  spec.email = [
    'stefano.verna@welaika.com',
    'ju.liu@welaika.com',
    'fabrizio.monti@welaika.com',
    'alessandro.fazzi@welaika.com',
    'filippo.gangidino@welaika.com'
  ]

  spec.summary       = 'Wordmove, Capistrano for Wordpress'
  spec.description   = 'Wordmove deploys your WordPress websites at the speed of light.'
  spec.homepage      = 'https://github.com/welaika/wordmove'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '~> 6.1'
  spec.add_runtime_dependency 'colorize', '~> 0.8.1'
  spec.add_runtime_dependency 'dotenv', '~> 2.7.5'
  spec.add_runtime_dependency 'dry-configurable', '~> 0.13.0'
  spec.add_runtime_dependency 'kwalify', '~> 0.7.2'
  spec.add_runtime_dependency 'light-service', '~> 0.17.0'
  spec.add_runtime_dependency 'photocopier', '~> 1.4', '>= 1.4.1'
  # spec.add_runtime_dependency 'thor', '~> 0.20.3'
  spec.add_runtime_dependency 'dry-cli', '~> 0.7.0'
  spec.add_runtime_dependency 'dry-files', '~> 0.1.0'

  spec.required_ruby_version = '>= 3.1.0'

  spec.add_development_dependency 'bundler', '~> 2.3.3'
  spec.add_development_dependency 'debug', '~> 1.4.0'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'rubocop', '~> 1.24.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.6.0'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'yard-activesupport-concern'

  spec.post_install_message = <<-RAINBOW
    Starting from version 3.0.0 `database.charset` option is no longer accepted.
    Pass the '--default-charecter-set' flag into `database.mysqldump_options` or to
    `database.mysql_options` instead, if you need to set the same option.

    Starting from version 3.0.0 the default `global.sql_adapter` is "wpcli".
    Therefor `WP-CLI` becomes a required peer dependency, unless you'll
    change to the "default" adapter.
  RAINBOW
end
