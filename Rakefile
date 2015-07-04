require "bundler/gem_tasks"
require "rake_compiler_dock"

task :build do
  sh "docker build -t larskanis/rake-compiler-dock:#{RakeCompilerDock::IMAGE_VERSION} ."
end

task :test do
  sh "ruby -w -W2 -I. -Ilib -e \"#{Dir["test/test_*.rb"].map{|f| "require '#{f}';"}.join}\" -- -v"
end
