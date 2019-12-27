require 'erb'
require "rake_compiler_dock"
require "rake_compiler_dock/gem_helper"

RakeCompilerDock::GemHelper.install_tasks

namespace :build do
  platforms = [
    ["x86-mingw32", "i686-w64-mingw32"],
    ["x64-mingw32", "x86_64-w64-mingw32"],
    ["x86-linux", "i686-linux-gnu"],
    ["x86_64-linux", "x86_64-linux-gnu"],
  ]
  platforms.each do |platform, target|
    desc "Build image for platform #{platform}"
    task platform do
      df = ERB.new(File.read("Dockerfile.mri.erb")).result(binding)
      File.write("Dockerfile.mri.#{platform}", df)
      sh "docker build -t larskanis/rake-compiler-dock-mri-#{platform}:#{RakeCompilerDock::IMAGE_VERSION} -f Dockerfile.mri.#{platform} ."
    end
  end

  desc "Build image for JRuby"
  task :jruby do
    sh "docker build -t larskanis/rake-compiler-dock-jruby:#{RakeCompilerDock::IMAGE_VERSION} -f Dockerfile.jruby ."
  end

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
