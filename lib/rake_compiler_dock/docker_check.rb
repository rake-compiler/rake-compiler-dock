require "rake_compiler_dock/colors"

module RakeCompilerDock
  class DockerCheck
    include Colors

    attr_reader :io

    def initialize(io)
      @io = io
      if !io.tty? || (RUBY_PLATFORM=~/mingw|mswin/ && RUBY_VERSION[/^\d+/] < '2')
        disable_colors
      else
        enable_colors
      end

      docker_version

      unless ok?
        b2d_version

        if b2d_avail?
          io.puts
          io.puts yellow("boot2docker is available, but not ready to use. Trying to start.")

          b2d_init
          if b2d_init_ok?
            b2d_start

            docker_version
          end
        end
      end
    end

    def docker_version
      @docker_version_text = `docker version 2>&1` rescue SystemCallError
      @docker_version_status = $?.exitstatus
    end

    def ok?
      @docker_version_status == 0 && @docker_version_text =~ /version/
    end

    def docker_client_avail?
      @docker_version_text =~ /version/
    end

    def b2d_version
      @b2d_version_text = `boot2docker version 2>&1` rescue SystemCallError
      @b2d_version_status = $?.exitstatus
    end

    def b2d_avail?
      @b2d_version_status == 0 && @b2d_version_text =~ /version/
    end

    def b2d_init
      system("boot2docker init") rescue SystemCallError
      @b2d_init_status = $?.exitstatus
    end

    def b2d_init_ok?
      @b2d_init_status == 0
    end

    def b2d_start
      @b2d_start_text = `boot2docker start` rescue SystemCallError
      @b2d_start_status = $?.exitstatus
      @b2d_start_envset = false

      if @b2d_start_status == 0
        @b2d_start_text.scan(/(unset |Remove-Item Env:\\)(?<key>.+?)$/) do |r, |
          io.puts "    #{$&}"
          ENV.delete(key)
          @b2d_start_envset = true
        end
        @b2d_start_text.scan(/(export |\$Env:)(?<key>.+?)(=| = ")(?<val>.*?)(|\")$/) do |key, val|
          io.puts "    #{$&}"
          ENV[key] = val
          @b2d_start_envset = true
        end
      end

      if @b2d_start_envset
        io.puts yellow("Using environment variables for further commands.")
      end
    end

    def b2d_start_ok?
      @b2d_start_status == 0
    end

    def b2d_start_has_env?
      @b2d_start_envset
    end

    def help_text
      help = []
      if !ok? && docker_client_avail? && !b2d_avail?
        help << red("Docker client tools work, but connection to the local docker server failed.")
        case RUBY_PLATFORM
        when /linux/
          help << yellow("Please make sure the docker daemon is running.")
          help << ""
          help << yellow("On Ubuntu/Debian:")
          help << "   sudo service docker start"
          help << yellow("or")
          help << "   sudo service docker.io start"
          help << ""
          help << yellow("On Fedora/Centos/RHEL")
          help << "   sudo systemctl start docker"
          help << ""
          help << yellow("On SuSE")
          help << "   sudo systemctl start docker"
          help << ""
          help << yellow("Then re-check with '") + white("docker version") + yellow("'")
          help << yellow("or have a look at the FAQs: http://git.io/vtD2Z")
        else
          help << yellow("    Please check why '") + white("docker version") + yellow("' fails")
          help << yellow("    or have a look at the FAQs: http://git.io/vtD2Z")
        end
      elsif !ok? && !b2d_avail?
        case RUBY_PLATFORM
        when /mingw|mswin/
          help << red("Docker is not available.")
          help << yellow("Please download and install boot2docker:")
          help << yellow("    https://github.com/boot2docker/windows-installer/releases")
        when /linux/
          help << red("Docker is not available.")
          help << ""
          help << yellow("Install on Ubuntu/Debian:")
          help << "    sudo apt-get install docker.io"
          help << ""
          help << yellow("Install on Fedora/Centos/RHEL")
          help << "    sudo yum install docker"
          help << "    sudo systemctl start docker"
          help << ""
          help << yellow("Install on SuSE")
          help << "    sudo zypper install docker"
          help << "    sudo systemctl start docker"
        when /darwin/
          help << red("Docker is not available.")
          help << yellow("Please download and install boot2docker:")
          help << yellow("    https://github.com/boot2docker/osx-installer/releases")
        else
          help << red("Docker is not available.")
        end
      elsif !ok? && !b2d_init_ok?
        help << red("boot2docker is installed but couldn't be initialized.")
        help << ""
        help << yellow("    Please check why '") + white("boot2docker init") + yellow("' fails")
        help << yellow("    or have a look at the FAQs: http://git.io/vtDBH")
      elsif !ok? && !b2d_start_ok?
        help << red("boot2docker is installed but couldn't be started.")
        help << ""
        help << yellow("    Please check why '") + white("boot2docker start") + yellow("' fails.")
        help << yellow("    You might need to re-init with '") + white("boot2docker delete") + yellow("'")
        help << yellow("    or have a look at the FAQs: http://git.io/vtDBH")
      elsif !ok? && b2d_start_ok?
        help << red("boot2docker is installed and started, but 'docker version' failed.")
        help << ""
        if b2d_start_has_env?
          help << yellow("    Please copy and paste above environment variables to your terminal")
          help << yellow("    and check why '") + white("docker version") + yellow("' fails.")
        else
          help << yellow("    Please check why '") + white("docker version") + yellow("' fails.")
        end
        help << yellow("    You might need to re-init with '") + white("boot2docker delete") + yellow("'")
        help << yellow("    or have a look at the FAQs: http://git.io/vtDBH")
      end

      help.join("\n")
    end

    def print_help_text
      io.puts(help_text)
    end
  end
end
