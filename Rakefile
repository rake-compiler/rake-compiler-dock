require "bundler/gem_tasks"
require "rake_compiler_dock"

task :build do
  sh "docker build -t larskanis/rake-compiler-dock:#{RakeCompilerDock::IMAGE_VERSION} ."
end
