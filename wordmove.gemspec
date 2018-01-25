lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wordmove/version'

Gem::Specification.new do |spec|
  spec.name          = "wordmove"
  spec.version       = Wordmove::VERSION
  spec.authors       = [
    "Stefano Verna", "Ju Liu", "Fabrizio Monti", "Alessandro Fazzi", "Filippo Gangi Dino"
  ]
  spec.email = [
    "stefano.verna@welaika.com",
    "ju.liu@welaika.com",
    "fabrizio.monti@welaika.com",
    "alessandro.fazzi@welaika.com",
    "filippo.gangidino@welaika.com"
  ]

  spec.summary       = "Wordmove, Capistrano for Wordpress"
  spec.description   = "Wordmove deploys your WordPress websites at the speed of light."
  spec.homepage      = "https://github.com/welaika/wordmove"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", '~> 5.1', '>= 5.1.1'
  spec.add_runtime_dependency "colorize", "~> 0.8.1"
  spec.add_runtime_dependency "kwalify", "~> 0"
  spec.add_runtime_dependency "photocopier", "~> 1.1", ">= 1.1.3"
  spec.add_runtime_dependency "thor", "~> 0.19.4"

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_development_dependency "bundler", "~> 1.14", ">= 1.14.6"
  spec.add_development_dependency "priscilla", "~> 1.0"
  spec.add_development_dependency "pry-byebug", "~> 3.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "rubocop", "~> 0.52.0"
  spec.add_development_dependency "simplecov", "~> 0.9"

  spec.post_install_message = <<-RAINBOW
    Starting from 2.1.0 you'll need to add the global section in your movefile.yml:
        global:
            sql_adapter: "default"
    Or you can spawn a new one with `wordmove init` (backup the old one!)

    Starting from 2.2.0 the default name of the config file is `movefile.yml`.
  RAINBOW
end
