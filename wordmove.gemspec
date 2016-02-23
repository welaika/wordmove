# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wordmove/version'

Gem::Specification.new do |spec|
  spec.name          = "wordmove"
  spec.version       = Wordmove::VERSION
  spec.authors       = ["Stefano Verna", "Ju Liu", "Fabrizio Monti", "Alessandro Fazzi"]
  spec.email         = [
    "stefano.verna@welaika.com",
    "ju.liu@welaika.com",
    "fabrizio.monti@welaika.com",
    "alessandro.fazzi@welaika.com"
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

  spec.add_dependency "colorize", "~> 0.7.5"
  spec.add_dependency "thor", "~> 0.19.1"
  spec.add_dependency "activesupport", "~> 4.2.1"
  spec.add_dependency "photocopier", "~> 1.1.0"

  spec.required_ruby_version = "~> 2.0"

  spec.add_development_dependency "bundler", ">= 1.6.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "simplecov", "~> 0.9"
  spec.add_development_dependency "pry-byebug", "~> 3.1"
  spec.add_development_dependency "priscilla", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 0.37.0"
  spec.add_development_dependency "gem-release"

  spec.post_install_message = <<-RAINBOW
    Starting from 1.4.0 Wordmove will compress SQL dumps both in remote and locale environments.
    If something will broke, please check if gzip executable is present locally and
    remotely. We are considering obvious it's installed in any web environment.
    Open an issue on github at your needs.
  RAINBOW
end
