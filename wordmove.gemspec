# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wordmove/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Stefano Verna", "Ju Liu"]
  gem.email         = ["stefano.verna@welaika.com", "ju.liu@welaika.com"]
  gem.description   = %q{Wordmove deploys your WordPress websites at the speed of light.}
  gem.summary       = %q{Wordmove, Capistrano for Wordpress}
  gem.homepage      = "https://github.com/welaika/wordmove"
  gem.license       = "MIT"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "wordmove"
  gem.require_paths = ["lib"]
  gem.version       = Wordmove::VERSION

  gem.add_dependency "colored", "~> 1.0"
  gem.add_dependency "rake", "~> 10.0"
  gem.add_dependency "thor", "~> 0.0"
  gem.add_dependency "activesupport", ">= 3.0", "< 5.0"
  gem.add_dependency "i18n", "~> 0.6"
  gem.add_dependency "photocopier", "~> 0.0"

  gem.add_development_dependency "rspec", "~> 2.0"
end

