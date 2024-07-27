
# We do ruby version check at runtime, so this file should be kept ruby-1.8 compatible.
if (m=RUBY_VERSION.match(/^(\d+)\.(\d+)\.(\d+)/)) &&
    m.captures.map(&:to_i).pack("N*") < [1,9,2].pack("N*")
  raise "rake-compiler-dock requires at least RUBY_VERSION >= 1.9.2"
end

require "rake_compiler_dock/colors"
require "rake_compiler_dock/docker_check"
require "rake_compiler_dock/starter"
require "rake_compiler_dock/version"
require "rake_compiler_dock/predefined_user_group"

module RakeCompilerDock

  # Run the command cmd within a fresh rake-compiler-dock container and within a shell.
  #
  # If a block is given, upon command completion the block is called with an OK flag (true on a zero exit status) and a Process::Status object.
  # Without a block a RuntimeError is raised when the command exits non-zero.
  #
  # Option +:verbose+ can be set to enable printing of the command line.
  # If not set, rake's verbose flag is used.
  #
  # Option +:rubyvm+ can be set to +:mri+ or +:jruby+ .
  # It selects the docker image with an appropriate toolchain.
  #
  # Option +:platform+ can be set to a list of space separated values.
  # It selects the docker image(s) with an appropriate toolchain.
  # Allowed values are +aarch64-linux-gnu+, +aarch64-linux-msul+, +arm-linux-gnu+, +arm-linux-musl+,
  # +arm64-darwin+, +x64-mingw-ucrt+, +x64-mingw32+, +x86-mingw32+, +x86_64-darwin+,
  # +x86_64-linux-gnu+, +x86_64-linux-musl+.
  # If the list contains multiple values, +cmd+ is consecutively executed in each of the docker images,
  # Option +:platform+ is ignored when +:rubyvm+ is set to +:jruby+.
  # Default is "x86-mingw32 x64-mingw32".
  #
  # Examples:
  #
  #   RakeCompilerDock.sh 'bundle && rake cross native gem'
  #
  # Check exit status after command runs:
  #
  #   sh %{bundle && rake cross native gem}, verbose: false do |ok, res|
  #     if ! ok
  #       puts "windows cross build failed (status = #{res.exitstatus})"
  #     end
  #   end
  def sh(cmd, options={}, &block)
    Starter.sh(cmd, options, &block)
  end

  def image_name
    Starter.image_name
  end

  # Run the command cmd within a fresh rake-compiler-dock container.
  # The command is run directly, without the shell.
  #
  # If a block is given, upon command completion the block is called with an OK flag (true on a zero exit status) and a Process::Status object.
  # Without a block a RuntimeError is raised when the command exits non-zero.
  #
  # * Option +:verbose+ can be set to enable printing of the command line.
  #   If not set, rake's verbose flag is used.
  # * Option +:check_docker+ can be set to false to disable the docker check.
  # * Option +:sigfw+ can be set to false to not stop the container on Ctrl-C.
  # * Option +:runas+ can be set to false to execute the command as user root.
  # * Option +:options+ can be an Array of additional options to the 'docker run' command.
  # * Option +:username+ can be used to overwrite the user name in the container
  # * Option +:groupname+ can be used to overwrite the group name in the container
  #
  # Examples:
  #
  #   RakeCompilerDock.exec 'bash', '-c', 'echo $RUBY_CC_VERSION'
  def exec(*args, &block)
    Starter.exec(*args, &block)
  end

  module_function :exec, :sh, :image_name
end
