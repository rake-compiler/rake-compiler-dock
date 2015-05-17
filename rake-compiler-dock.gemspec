# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake_compiler_dock/version'

Gem::Specification.new do |spec|
  spec.name          = "rake-compiler-dock"
  spec.version       = RakeCompilerDock::VERSION
  spec.authors       = ["Lars Kanis"]
  spec.email         = ["lars@greiz-reinsdorf.de"]
  spec.summary       = %q{run rake-compiler build environment}
  spec.description   = %q{run rake-compiler build environment with docker}
  spec.homepage      = "https://github.com/larskanis/rake-compiler-dock"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
