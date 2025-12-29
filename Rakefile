require 'erb'
require "rake/clean"
require "rake_compiler_dock"
require_relative "build/gem_helper"
require_relative "build/parallel_docker_build"

CLEAN.include("tmp")

RakeCompilerDock::GemHelper.install_tasks

def build_mri_images(platforms, host_platforms, output: )
  plats = host_platforms.map(&:first).join(",")
  platforms.each do |platform, _|
    sdf = "tmp/docker/Dockerfile.mri.#{platform}"
    image_name = RakeCompilerDock::Starter.container_image_name(platform: platform)

    tags = [image_name]
    tags << image_name.sub("linux-gnu", "linux") if image_name.include?("linux-gnu")
    RakeCompilerDock.docker_build(sdf, tag: tags, platform: plats, output: output)
  end
end

def build_jruby_images(host_platforms, output: )
  image_name = RakeCompilerDock::Starter.container_image_name(rubyvm: "jruby")
  plats = host_platforms.map(&:first).join(",")
  sdf = "tmp/docker/Dockerfile.jruby"
  RakeCompilerDock.docker_build(sdf, tag: image_name, platform: plats, output: output)
end

platforms = [
  # tuple is [platform, target]
  ["aarch64-linux-gnu", "aarch64-linux-gnu"],
  ["aarch64-linux-musl", "aarch64-linux-musl"],
  ["aarch64-mingw-ucrt", "aarch64-w64-mingw32"],
  ["arm-linux-gnu", "arm-linux-gnueabihf"],
  ["arm-linux-musl", "arm-linux-musleabihf"],
  ["arm64-darwin", "aarch64-apple-darwin"],
  ["x64-mingw-ucrt", "x86_64-w64-mingw32"],
  ["x64-mingw32", "x86_64-w64-mingw32"],
  ["x86-linux-gnu", "i686-linux-gnu"],
  ["x86-linux-musl", "i686-unknown-linux-musl"],
  ["x86-mingw32", "i686-w64-mingw32"],
  ["x86_64-darwin", "x86_64-apple-darwin"],
  ["x86_64-linux-gnu", "x86_64-linux-gnu"],
  ["x86_64-linux-musl", "x86_64-unknown-linux-musl"],
]

host_platforms = [
  # tuple is [docker platform, RUBY_PLATFORM matcher]
  ["linux/amd64", /^x86_64|^x64|^amd64/],
  ["linux/arm64", /^aarch64|arm64/],
]
local_platform = host_platforms.find { |_,reg| reg =~ RUBY_PLATFORM } or
    raise("RUBY_PLATFORM #{RUBY_PLATFORM} is not supported as host")

mkdir_p "tmp/docker"

docker_platform, _ = local_platform
platforms.each do |platform, target|
  sdf = "tmp/docker/Dockerfile.mri.#{platform}"
  df = ERB.new(File.read("Dockerfile.mri.erb"), trim_mode: ">").result(binding)
  File.write(sdf, df)
  CLEAN.include(sdf)
end
sdf = "tmp/docker/Dockerfile.jruby"
df = File.read("Dockerfile.jruby")
File.write(sdf, df)

parallel_docker_build = RakeCompilerDock::ParallelDockerBuild.new(platforms.map{|pl, _| "tmp/docker/Dockerfile.mri.#{pl}" } + ["tmp/docker/Dockerfile.jruby"], workdir: "tmp/docker", task_prefix: "common-")

namespace :build do
  parallel_docker_build.define_file_tasks platform: docker_platform

  # The jobs in the CI pipeline are already organized in a tree structure.
  # So we can avoid unnecessary rebuilds by omitting the dependecies.
  unless ENV['RCD_TASK_DEPENDENCIES'] = "false"
    parallel_docker_build.define_tree_tasks
    parallel_docker_build.define_final_tasks
  end

  platforms.each do |platform, target|
    sdf = "tmp/docker/Dockerfile.mri.#{platform}"

    # Load image after build on local platform only
    desc "Build and load image for platform #{platform} on #{docker_platform}"
    task platform => sdf do
      build_mri_images([platform], [local_platform], output: 'load')
    end
    multitask :images => platform
  end

  sdf = "tmp/docker/Dockerfile.jruby"
  # Load image after build on local platform only
  desc "Build and load image for JRuby on #{docker_platform}"
  task :jruby => sdf do
    build_jruby_images([local_platform], output: 'load')
  end
  multitask :images => :jruby

  all_mri_images = platforms.map(&:first)
  desc "Build images for all MRI platforms in parallel"
  if ENV['RCD_USE_BUILDX_CACHE']
    task :mri => all_mri_images
  else
    multitask :mri => all_mri_images
  end

  all_images = all_mri_images + ["jruby"]
  desc "Build images for all platforms in parallel"
  if ENV['RCD_USE_BUILDX_CACHE']
    task :images => all_images
  else
    multitask :images => all_images
  end
end

namespace :release do
  host_pl = host_platforms.map(&:first).join(",")

  desc "Push image for JRuby on #{host_pl}"
  task :jruby do
    build_jruby_images(host_platforms, output: 'push')
  end

  desc "Push all docker images on #{host_pl}"
  multitask :images => :jruby

  platforms.each do |platform, target|
    desc "Push image for platform #{platform} on #{host_pl}"
    task platform do
      build_mri_images([platform], host_platforms, output: 'push')
    end

    desc "Push all docker images on #{host_pl}"
    multitask :images => platform
  end

  desc "Show download sizes of the release images"
  task :sizes do
    require "yaml"

    ths = platforms.map do |pl, _|
      image_name = RakeCompilerDock::Starter.container_image_name(platform: pl)
      Thread.new do
        [ pl,
          IO.popen("docker manifest inspect #{image_name} -v", &:read)
        ]
      end
    end

    hlayers = Hash.new{|h,k| h[k] = {} }
    isize_sums = Hash.new{|h,k| h[k] = 0 }

    ths.map(&:value).each do |pl, ystr|
      y = YAML.load(ystr)
      y = [y] unless y.is_a?(Array)
      y.each do |img|
        next unless img
        host_pl = "#{img.dig("Descriptor", "platform", "architecture")}-#{
        img.dig("Descriptor", "platform", "os")}"
        next if host_pl=="unknown-unknown"
        lays = img.dig("OCIManifest", "layers") || img.dig("SchemaV2Manifest", "layers")
        isize = lays.map do |lay|
          hlayers[host_pl][lay["digest"]] = lay["size"]
        end.sum
        isize_sums[host_pl] += isize
        puts format("%-15s %-20s:%12d MB", host_pl, pl, isize/1024/1024)
      end
    end
    puts "----------"
    isize_sums.each do |host_pl, isize|
      puts format("%-15s %-20s:%12d MB", host_pl, "all-separate", isize/1024/1024)
    end
    hlayers.each do |host_pl, layers|
      asize = layers.values.sum
      puts format("%-15s %-20s:%12d MB", host_pl, "all-combined", asize/1024/1024)
    end
  end
end

namespace :prepare do
  desc "Build cross compiler for x64-mingw-ucrt aka RubyInstaller-3.1+"
  task "mingw64-ucrt" do
    sh(*RakeCompilerDock.docker_build_cmd, "-t", "larskanis/mingw64-ucrt:20.04", ".",
       chdir: "mingw64-ucrt")
  end
end

desc "Run tests"
task :test do
  sh %Q{ruby -w -W2 -I. -Ilib -e "#{Dir["test/test_*.rb"].map{|f| "require '#{f}';"}.join}" -- -v #{ENV['TESTOPTS']}}
end

desc "Update predefined_user_group.rb"
task :update_lists do
  def get_user_list(platform)
    puts "getting user list from #{platform} ..."
    `RCD_PLATFORM=#{platform} rake-compiler-dock bash -c "getent passwd"`.each_line.map do |line|
      line.chomp.split(":")[0]
    end.compact.reject(&:empty?) - [RakeCompilerDock::Starter.make_valid_user_name(`id -nu`.chomp)]
  end

  def get_group_list(platform)
    puts "getting group list from #{platform} ..."
    `RCD_PLATFORM=#{platform} rake-compiler-dock bash -c "getent group"`.each_line.map do |line|
      line.chomp.split(":")[0]
    end.compact.reject(&:empty?) - [RakeCompilerDock::Starter.make_valid_group_name(`id -ng`.chomp)]
  end

  users = platforms.flat_map { |platform, _| get_user_list(platform) }.uniq.sort
  groups = platforms.flat_map { |platform, _| get_group_list(platform) }.uniq.sort

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

desc "Update CI publish workflows from erb"
namespace :ci do
  task :update_workflows do
    erb = ERB.new(File.read(".github/workflows/publish-images.yml.erb"))
    sdf = ".github/workflows/publish-images.yml"
    release = false
    File.write(sdf, erb.result(binding))
    sdf = ".github/workflows/release-images.yml"
    release = true
    File.write(sdf, erb.result(binding))
    erb = ERB.new(File.read(".github/workflows/ci.yml.erb"))
    sdf = ".github/workflows/ci.yml"
    File.write(sdf, erb.result(binding))
  end
end
