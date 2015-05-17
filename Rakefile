require "bundler/gem_tasks"

task :build do
  sh "docker build -t rake-compiler-dock ."
end

task :gem => :build
