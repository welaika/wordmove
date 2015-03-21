# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wordmove/version'

Gem::Specification.new do |spec|
  spec.name          = "wordmove"
  spec.version       = Wordmove::VERSION
  spec.authors       = ["Stefano Verna", "Ju Liu", "Fabrizio Monti", "Alessandro Fazzi"]
  spec.email         = ["stefano.verna@welaika.com", "ju.liu@welaika.com", "fabrizio.monti@welaika.com", "alessandro.fazzi@gmail.com"]

  spec.summary       = %q{Wordmove, Capistrano for Wordpress}
  spec.description   = %q{Wordmove deploys your WordPress websites at the speed of light.}
  spec.homepage      = "https://github.com/welaika/wordmove"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "colored"
  spec.add_dependency "rake"
  spec.add_dependency "thor"
  spec.add_dependency "activesupport"
  spec.add_dependency "i18n"
  spec.add_dependency "photocopier", "~> 0.0.10"
  spec.add_dependency "escape"

  spec.required_ruby_version = "~> 2.0"

  spec.add_development_dependency "bundler", ">= 1.6.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "pry-byebug", "~> 3.1"

  spec.post_install_message = <<-EOF

============================================================================
Beware! From version 1.0, we have changed the wordmove flags' behaviour:
they used to tell wordmove what to _skip_, now they tell what to _include_.

Read `wordmove help` for more info.
============================================================================

  EOF
end
