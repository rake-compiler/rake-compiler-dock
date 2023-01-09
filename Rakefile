require 'erb'
require "rake/clean"
require "rake_compiler_dock"
require_relative "build/gem_helper"
require_relative "build/parallel_docker_build"

RakeCompilerDock::GemHelper.install_tasks

docker_build_cmd = Shellwords.split(ENV['RCD_DOCKER_BUILD'] || "docker build")

platforms = [
  ["x86-mingw32", "i686-w64-mingw32"],
  ["x64-mingw32", "x86_64-w64-mingw32"],
  ["x64-mingw-ucrt", "x86_64-w64-mingw32"],
  ["x86-linux", "i686-redhat-linux"],
  ["x86_64-linux", "x86_64-redhat-linux"],
  ["x86_64-darwin", "x86_64-apple-darwin"],
  ["arm64-darwin", "aarch64-apple-darwin"],
  ["arm-linux", "arm-linux-gnueabihf"],
  ["aarch64-linux", "aarch64-linux-gnu"],
]

namespace :build do

  platforms.each do |platform, target|
    sdf = "Dockerfile.mri.#{platform}"

    desc "Build image for platform #{platform}"
    task platform => sdf
    task sdf do
      image_name = RakeCompilerDock::Starter.container_image_name(platform: platform)
      sh(*docker_build_cmd, "-t", image_name, "-f", "Dockerfile.mri.#{platform}", ".")
    end

    df = ERB.new(File.read("Dockerfile.mri.erb"), trim_mode: ">").result(binding)
    File.write(sdf, df)
    CLEAN.include(sdf)
  end

  desc "Build image for JRuby"
  task :jruby => "Dockerfile.jruby"
  task "Dockerfile.jruby" do
    image_name = RakeCompilerDock::Starter.container_image_name(rubyvm: "jruby")
    sh(*docker_build_cmd, "-t", image_name, "-f", "Dockerfile.jruby", ".")
  end

  RakeCompilerDock::ParallelDockerBuild.new(platforms.map{|pl, _| "Dockerfile.mri.#{pl}" } + ["Dockerfile.jruby"], workdir: "tmp/docker", docker_build_cmd: docker_build_cmd)

  desc "Build images for all MRI platforms in parallel"
  multitask :mri => platforms.map(&:first)

  desc "Build images for all platforms in parallel"
  multitask :all => platforms.map(&:first) + ["jruby"]
end

task :build => "build:all"

namespace :prepare do
  desc "Build cross compiler for x64-mingw-ucrt aka RubyInstaller-3.1+"
  task "mingw64-ucrt" do
    sh(*docker_build_cmd, "-t", "larskanis/mingw64-ucrt:20.04", ".",
       chdir: "mingw64-ucrt")
  end
end

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

namespace :release do
  desc "push all docker images"
  task :images do
    image_name = RakeCompilerDock::Starter.container_image_name(rubyvm: "jruby")
    sh("docker", "push", image_name)

    platforms.each do |platform, _|
      image_name = RakeCompilerDock::Starter.container_image_name(platform: platform)
      sh("docker", "push", image_name)
    end
  end
end
