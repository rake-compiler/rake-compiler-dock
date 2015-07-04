# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake_compiler_dock/version'

Gem::Specification.new do |spec|
  spec.name          = "rake-compiler-dock"
  spec.version       = RakeCompilerDock::VERSION
  spec.authors       = ["Lars Kanis"]
  spec.email         = ["lars@greiz-reinsdorf.de"]
  spec.summary       = %q{Easy to use and reliable cross compiler environment for building Windows binary gems.}
  spec.description   = %q{Easy to use and reliable cross compiler environment for building Windows binary gems.
Use rake-compiler-dock to enter an interactive shell session or add a task to your Rakefile to automate your cross build.}
  spec.homepage      = "https://github.com/larskanis/rake-compiler-dock"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
end
