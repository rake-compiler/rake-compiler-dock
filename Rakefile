require 'erb'
require "rake/clean"
require "rake_compiler_dock"
require_relative "build/gem_helper"
require_relative "build/parallel_docker_build"

RakeCompilerDock::GemHelper.install_tasks

DOCKERHUB_USER = ENV['DOCKERHUB_USER'] || "larskanis"
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

    # Native images to alleviate qemu slowness, and manylinux2014 provides per-arch
    # images. But they are not yet conformant to the Docker platform spec (i.e.
    # amd64/linux). We have to do some string manipulation to get the right for
    # now, but you should be able to nuke this code soon, and rely on only the
    # buildx `--platform` feature instead....
    #
    # See: https://github.com/pypa/manylinux/issues/1306
    manylinux_cpu, dpkg_arch = case ENV["DOCKER_BUILD_PLATFORM"]
    when /arm64/
      ["aarch64", "arm64"]
    when /amd64/
      ["x86_64", "amd64"]
    else
      if ENV["CI"]
        raise "Couldnt infer manylinux CPU for #{ENV["DOCKER_BUILD_PLATFORM"].inspect}"
      else
        ["x86_64", "amd64"]
      end
    end

    manylinux_image = "quay.io/pypa/manylinux2014_#{manylinux_cpu}"

    desc "Build image for platform #{platform}"
    task platform => sdf
    task sdf do
      sh(*docker_build_cmd, "-t", "#{DOCKERHUB_USER}/rake-compiler-dock-mri-#{platform}:#{RakeCompilerDock::IMAGE_VERSION}", "-f", "Dockerfile.mri.#{platform}", ".")
    end

    df = ERB.new(File.read("Dockerfile.mri.erb"), trim_mode: ">").result(binding)
    File.write(sdf, df)
    CLEAN.include(sdf)
  end

  desc "Build image for JRuby"
  task :jruby => "Dockerfile.jruby"
  task "Dockerfile.jruby" do
    sh(*docker_build_cmd, "-t", "#{DOCKERHUB_USER}/rake-compiler-dock-jruby:#{RakeCompilerDock::IMAGE_VERSION}", "-f", "Dockerfile.jruby", ".")
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
    sh(*docker_build_cmd, "-t", "#{DOCKERHUB_USER}/mingw64-ucrt:20.04", ".",
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
    jimg = "#{DOCKERHUB_USER}/rake-compiler-dock-jruby:#{RakeCompilerDock::IMAGE_VERSION}"
    sh "docker", "push", jimg

    platforms.each do |platform, _|
      img = "#{DOCKERHUB_USER}/rake-compiler-dock-mri-#{platform}:#{RakeCompilerDock::IMAGE_VERSION}"
      sh "docker", "push", img
    end
  end
end
