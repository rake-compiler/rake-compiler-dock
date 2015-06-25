require "shellwords"
require "rake_compiler_dock/version"

module RakeCompilerDock
  class DockerIsNotAvailable < RuntimeError
  end

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
    if verbose_flag(options)
      $stderr.puts "rake-compiler-dock bash -c #{ cmd.inspect }"
    end
    exec('bash', '-c', cmd, options, &block)
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
    options = (Hash === args.last) ? args.pop : {}
    runargs = args.dup

    check_docker if options.fetch(:check_docker){ true }
    runargs.unshift("sigfw") if options.fetch(:sigfw){ true }
    runargs.unshift("runas") if options.fetch(:runas){ true }

    case RUBY_PLATFORM
    when /mingw|mswin/
      # Change Path from "C:\Path" to "/c/Path" as used by boot2docker
      pwd = Dir.pwd.gsub(/^([a-z]):/i){ "/#{$1.downcase}" }
      uid = 1000
      gid = 1000
    when /darwin/
      pwd = Dir.pwd
      uid = 1000
      gid = Process.gid
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
          "-e", "ftp_proxy=#{ENV['ftp_proxy']}",
          "-e", "http_proxy=#{ENV['http_proxy']}",
          "-e", "https_proxy=#{ENV['https_proxy']}",
          "-w", pwd,
          image_name,
          *runargs]

    cmdline = Shellwords.join(cmd)
    if verbose_flag(options) == true
      $stderr.puts cmdline
    end

    ok = system(*cmd)
    if block_given?
      yield(ok, $?)
    elsif !ok
      fail "Command failed with status (#{$?.exitstatus}): " +
        "[#{cmdline}]"
    end
  end

  def verbose_flag(options)
    verbose = options.fetch(:verbose) do
      Object.const_defined?(:Rake) && Rake.const_defined?(:FileUtilsExt) ? Rake::FileUtilsExt.verbose_flag : false
    end
  end

  @@docker_checked = false

  def check_docker
    return if @@docker_checked

    version_text = `docker version` rescue SystemCallError
    if $?.exitstatus == 0 && version_text.to_s =~ /version/
      @@docker_checked = true
    else
      at_exit do
        $stderr.puts
        case RUBY_PLATFORM
        when /mingw|mswin/
          $stderr.puts "Docker is not available. Please download and install boot2docker:"
          $stderr.puts "   https://github.com/boot2docker/windows-installer/releases"
          $stderr.puts
          $stderr.puts "Then execute 'boot2docker start' and follow the instuctions"
        when /linux/
          $stderr.puts "Docker is not available."
          $stderr.puts
          $stderr.puts "Install on Ubuntu/Debian:"
          $stderr.puts "   sudo apt-get install docker.io"
          $stderr.puts
          $stderr.puts "Install on Fedora/Centos/RHEL"
          $stderr.puts "   sudo yum install docker"
          $stderr.puts "   sudo systemctl start docker"
          $stderr.puts
          $stderr.puts "Install on SuSE"
          $stderr.puts "   sudo zypper install docker"
          $stderr.puts "   sudo systemctl start docker"
        when /darwin/
          $stderr.puts "Docker is not available. Please download and install boot2docker:"
          $stderr.puts "   https://github.com/boot2docker/osx-installer/releases"
        else
          $stderr.puts "Docker is not available."
        end
      end
      raise DockerIsNotAvailable, "Docker is not available"
    end
  end

  module_function :exec, :sh, :image_name, :verbose_flag, :check_docker
end
