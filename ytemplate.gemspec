# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ytemplate/version"

Gem::Specification.new do |s|
  s.name        = "ytemplate"
  s.version     = YAML::Template::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors      = [ 'Малъ Скрылёвъ (Malo Skrylevo)' ]
  s.email        = [ '3aHyga@gmail.com' ]
  s.homepage     = 'https://github.com/3aHyga/ytemplate'
  s.summary      = 'YAML template deployment extension'
  s.description  = 'ytemplate is YAML extension allowing deployment of YAML templates'

  s.rubyforge_project = "ytemplate"

  s.required_rubygems_version = '>= 1.6.0'

  s.add_dependency 'rdoba', ">= 0.1"

  s.add_development_dependency("bundler", ">= 1.0.0")
  s.add_development_dependency("rspec", "~> 2.0.1")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
