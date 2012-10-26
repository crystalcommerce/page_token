# -*- encoding: utf-8 -*-
require File.expand_path('../lib/page_token/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Xavier", "Donald Plummer"]
  gem.email         = ["xavier@crystalcommerce.com", "donald@crystalcommerce.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "page_token"
  gem.require_paths = ["lib"]
  gem.version       = PageToken::VERSION

  gem.add_dependency("redis", "~> 3.0.2")
  gem.add_dependency("redis-namespace", "~> 1.2.1")

  gem.add_development_dependency("fivemat", "~> 1.1.0")
  gem.add_development_dependency("guard", "~> 1.2.1")
  gem.add_development_dependency("guard-rspec", "~> 1.1.0")
  gem.add_development_dependency("pry", "~> 0.9.10")
  gem.add_development_dependency("pry-doc", "~> 0.4.4")
  gem.add_development_dependency("pry-nav", "~> 0.2.2")
  gem.add_development_dependency("rake", "~> 0.9.2")
  gem.add_development_dependency("rb-inotify", "~> 0.8.8")
  gem.add_development_dependency("rspec", "~> 2.11.0")
end
