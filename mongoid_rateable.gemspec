# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: mongoid_rateable 0.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mongoid_rateable".freeze
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Petr Savichev (proton)".freeze]
  s.date = "2023-03-07"
  s.description = "Provides fields and methods for the rating manipulation on Mongoid documents.".freeze
  s.email = "psavichev@gmail.com".freeze
  s.extra_rdoc_files = [
    "CHANGELOG.md",
    "LICENSE.txt",
    "README.md",
    "TODO"
  ]
  s.files = [
    ".github/FUNDING.yml",
    ".rspec",
    ".ruby-version",
    ".travis.yml",
    "Appraisals",
    "CHANGELOG.md",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "TODO",
    "VERSION",
    "gemfiles/mongoid_3.gemfile",
    "gemfiles/mongoid_3.gemfile.lock",
    "gemfiles/mongoid_4.gemfile",
    "gemfiles/mongoid_4.gemfile.lock",
    "gemfiles/mongoid_5.gemfile",
    "gemfiles/mongoid_5.gemfile.lock",
    "gemfiles/mongoid_6.gemfile",
    "gemfiles/mongoid_6.gemfile.lock",
    "gemfiles/mongoid_7.gemfile",
    "gemfiles/mongoid_7.gemfile.lock",
    "gemfiles/mongoid_8.gemfile",
    "gemfiles/mongoid_8.gemfile.lock",
    "lib/mongoid_rateable.rb",
    "lib/mongoid_rateable/rateable.rb",
    "lib/mongoid_rateable/rating.rb",
    "mongoid_rateable.gemspec",
    "spec/models/article.rb",
    "spec/models/comment.rb",
    "spec/models/post.rb",
    "spec/models/user.rb",
    "spec/rateable_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/database_cleaner.rb"
  ]
  s.homepage = "http://github.com/proton/mongoid_rateable".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Rating functionality for Mongoid documents".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<mongoid>.freeze, [">= 3.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<jeweler>.freeze, ["~> 2.1.1"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.0.0"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<database_cleaner-mongoid>.freeze, ["~> 2.0", ">= 2.0.1"])
end

