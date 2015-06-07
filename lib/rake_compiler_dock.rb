require "rake_compiler_dock/version"

module RakeCompilerDock
  # Run the command cmd within a fresh rake-compiler-dock container and within a shell.
  #
  # If a block is given, upon command completion the block is called with an OK flag (true on a zero exit status) and a Process::Status object.
  # Without a block a RuntimeError is raised when the command exits non-zero.
  #
  # Examples:
  #
  #   RakeCompilerDock.sh 'bundle && rake cross native gem'
  #
  #   # check exit status after command runs
  #   sh %{bundle && rake cross native gem} do |ok, res|
  #     if ! ok
  #       puts "windows cross build failed (status = #{res.exitstatus})"
  #     end
  #   end
  def sh(cmd, &block)
    exec('bash', '-c', cmd, &block)
  end

  def image_name
    ENV['RAKE_COMPILER_DOCK_IMAGE'] || "larskanis/rake-compiler-dock:#{VERSION}"
  end

  # Run the command cmd within a fresh rake-compiler-dock container.
  # The command is run directly, without the shell.
  #
  # If a block is given, upon command completion the block is called with an OK flag (true on a zero exit status) and a Process::Status object.
  # Without a block a RuntimeError is raised when the command exits non-zero.
  #
  # Examples:
  #
  #   RakeCompilerDock.exec 'bash', '-c', 'echo $RUBY_CC_VERSION'
  def exec(*args)
    if RUBY_PLATFORM =~ /mingw|mswin/
      # Change Path from "C:\Path" to "/c/Path" as used by boot2docker
      pwd = Dir.pwd.gsub(/^([a-z]):/i){ "/#{$1.downcase}" }
      uid = 1000
      gid = 1000
    else
      pwd = Dir.pwd
      uid = Process.uid
      gid = Process.gid
    end
    user = `id -nu`.chomp
    group = `id -ng`.chomp

    cmd = ["docker", "run", "--rm", "-i", "-t",
          "-v", "#{pwd}:#{pwd}",
          "-e", "UID=#{uid}",
          "-e", "GID=#{gid}",
          "-e", "USER=#{user}",
          "-e", "GROUP=#{group}",
          "-w", pwd,
          image_name,
          "sigfw", "runas", *args]

    ok = system(*cmd)
    if block_given?
      yield(ok, $?)
    elsif !ok
      show_command = cmd.join(" ")
      fail "Command failed with status (#{$?.exitstatus}): " +
        "[#{show_command}]"
    end
  end

  module_function :exec, :sh, :image_name
end
