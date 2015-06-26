require "rake_compiler_dock/version"
require "rake_compiler_dock/starter"

module RakeCompilerDock

  # Run the command cmd within a fresh rake-compiler-dock container and within a shell.
  #
  # If a block is given, upon command completion the block is called with an OK flag (true on a zero exit status) and a Process::Status object.
  # Without a block a RuntimeError is raised when the command exits non-zero.
  #
  # Option +:verbose+ can be set to enable printing of the command line.
  # If not set, rake's verbose flag is used.
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
  #
  # Examples:
  #
  #   RakeCompilerDock.exec 'bash', '-c', 'echo $RUBY_CC_VERSION'
  def exec(*args)
    Starter.exec(*args)
  end

  module_function :exec, :sh, :image_name
end
