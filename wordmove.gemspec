# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wordmove/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Stefano Verna"]
  gem.email         = ["stefano.verna@welaika.com"]
  gem.description   = %q{Capistrano for Wordpress}
  gem.summary       = %q{Capistrano for Wordpress}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "wordmove"
  gem.require_paths = ["lib"]
  gem.version       = Wordmove::VERSION

  gem.add_dependency "colored"
  gem.add_dependency "rake"
  gem.add_dependency "thor"
  gem.add_dependency "activesupport"
  gem.add_dependency "i18n"
  gem.add_dependency "photocopier", ">= 0.0.6"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "cucumber"
  gem.add_development_dependency "aruba"

  gem.post_install_message = "Beware! We have changed the wordmove flags' behaviour: they used to tell wordmove what to _skip_, now they tell what to _include_. Read `wordmove help` for more info."
end
