require "rake_compiler_dock"
require "rake_compiler_dock/gem_helper"

RakeCompilerDock::GemHelper.install_tasks

task :build do
  sh "docker build -t larskanis/rake-compiler-dock-mri:#{RakeCompilerDock::IMAGE_VERSION} -f Dockerfile.mri ."
  sh "docker build -t larskanis/rake-compiler-dock-jruby:#{RakeCompilerDock::IMAGE_VERSION} -f Dockerfile.jruby ."
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
