require 'erb'
require "rake/clean"
require "rake_compiler_dock"
require_relative "build/gem_helper"
require_relative "build/parallel_docker_build"

RakeCompilerDock::GemHelper.install_tasks

DOCKERHUB_USER = ENV['DOCKERHUB_USER'] || "larskanis"

namespace :build do
  platforms = [
    ["x86-mingw32", "i686-w64-mingw32"],
    ["x64-mingw32", "x86_64-w64-mingw32"],
    ["x86-linux", "i686-linux-gnu"],
    ["x86_64-linux", "x86_64-linux-gnu"],
    ["x86_64-darwin", "x86_64-apple-darwin19"],
  ]
  platforms.each do |platform, target|
    sdf = "Dockerfile.mri.#{platform}"

    desc "Build image for platform #{platform}"
    task platform => sdf
    task sdf do
      sh "docker build -t #{DOCKERHUB_USER}/rake-compiler-dock-mri-#{platform}:#{RakeCompilerDock::IMAGE_VERSION} -f Dockerfile.mri.#{platform} ."
    end

    df = ERB.new(File.read("Dockerfile.mri.erb")).result(binding)
    File.write(sdf, df)
    CLEAN.include(sdf)
  end

  desc "Build image for JRuby"
  task :jruby => "Dockerfile.jruby"
  task "Dockerfile.jruby" do
    sh "docker build -t #{DOCKERHUB_USER}/rake-compiler-dock-jruby:#{RakeCompilerDock::IMAGE_VERSION} -f Dockerfile.jruby ."
  end

  RakeCompilerDock::ParallelDockerBuild.new(platforms.map{|pl, _| "Dockerfile.mri.#{pl}" } + ["Dockerfile.jruby"], workdir: "tmp/docker")

  desc "Build images for all MRI platforms in parallel"
  multitask :mri => platforms.map(&:first)

  desc "Build images for all platforms in parallel"
  multitask :all => platforms.map(&:first) + ["jruby"]
end

task :build => "build:all"

desc "Run tests"
task :test do
  sh "ruby -w -W2 -I. -Ilib -e \"#{Dir["test/test_*.rb"].map{|f| "require '#{f}';"}.join}\" -- -v"
end

desc "Update predefined_user_group.rb"
task :update_lists do

  users = `rake-compiler-dock bash -c "getent passwd"`.each_line.map do |line|
    line.chomp.split(":")[0]
  end.compact.reject(&:empty?) - [RakeCompilerDock::Starter.make_valid_user_name(`id -nu`.chomp)]

  groups = `rake-compiler-dock bash -c "getent group"`.each_line.map do |line|
    line.chomp.split(":")[0]
  end.compact.reject(&:empty?) - [RakeCompilerDock::Starter.make_valid_group_name(`id -ng`.chomp)]

  File.open("lib/rake_compiler_dock/predefined_user_group.rb", "w") do |fd|
    fd.puts <<-EOT
      # DO NOT EDIT - This file is generated per 'rake update_lists'
      module RakeCompilerDock
        PredefinedUsers = #{users.inspect}
        PredefinedGroups = #{groups.inspect}
      end
    EOT
  end
end
