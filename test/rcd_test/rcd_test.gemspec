# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "rcd_test"
  spec.version       = "1.0.0"
  spec.authors       = ["Lars Kanis"]
  spec.email         = ["lars@greiz-reinsdorf.de"]

  spec.summary       = "C extension for testing rake-compiler-dock"
  spec.description   = "This gem has no real use other than testing builds of binary gems."
  spec.homepage      = "https://github.com/rake-compiler/rake-compiler-dock"
  spec.required_ruby_version = ">= 2.0.0"
  spec.license = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  unless RUBY_ENGINE == "jruby"
    spec.extensions    = ["ext/mri/extconf.rb"]
  end

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
end
