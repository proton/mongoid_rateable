# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid_rateable/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_rateable"
  s.version     = MongoidRateable::VERSION
  s.authors     = [%q{Peter Savichev (proton)}]
  s.date = %q{2011-09-27}
  s.description = %q{Provides fields and methods for the rating manipulation on Mongoid documents.}
  s.email = %q{psavichev@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc",
    "TODO"
  ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "database_cleaner"

  s.add_runtime_dependency "mongoid", [">= 3.0"]
end