# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'lib/live_ast/version.rb')

Gem::Specification.new do |spec|
  spec.name = 'live_ast'
  spec.version = LiveAST::VERSION

  spec.summary = "Live abstract syntax trees of methods and procs."

  spec.authors = ["James M. Lawrence"]
  spec.email = ["quixoticsycophant@gmail.com"]
  spec.homepage = "http://quix.github.com/live_ast"

  spec.license = "MIT"

  spec.description = <<-DESC
    LiveAST enables a program to find the ASTs of objects created by dynamically
    generated code.
  DESC

  spec.required_ruby_version = ">= 1.9.2"

  spec.files = Dir[ '{devel,lib,test}/**/*.rb',
                    "*.rdoc",
                    "Rakefile", ]
  spec.test_files = Dir[ 'test/**/*.rb' ]

  spec.add_runtime_dependency "ruby_parser", "~> 3.2.2"
  spec.add_runtime_dependency "ruby2ruby"

  spec.add_development_dependency "boc"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "minitest", "~> 4.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"

  spec.rdoc_options = [ "--main", "README.rdoc",
                        "--title", "LiveAST: Live Abstract Syntax Trees",
                        "--visibility", "private" ]
  spec.extra_rdoc_files = [ "README.rdoc", "CHANGES.rdoc" ]

  spec.require_paths = ["lib"]
end
