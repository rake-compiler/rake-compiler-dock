module RakeCompilerDock
  class DockerCheck
    def initialize
      docker_version

      unless ok?
        b2d_version

        if b2d_avail?
          $stderr.puts
          $stderr.puts "boot2docker is available, but not ready to use. Trying to start."

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

      if @b2d_start_status == 0
        @b2d_start_text.scan(/(unset |Remove-Item Env:\\)(?<key>.+?)$/) do |r, |
          $stderr.puts "    unset #{key}"
          ENV.delete(key)
        end
        @b2d_start_text.scan(/(export |\$Env:)(?<key>.+?)(=| = ")(?<val>.*?)(|\")$/) do |key, val|
          ENV[key] = val
          $stderr.puts "    set #{key}=#{val}"
        end
      end
    end

    def b2d_start_ok?
      @b2d_start_status == 0
    end

    def help_text
      help = []
      if !ok? && docker_client_avail? && !b2d_avail?
        help << "Docker client tools work, but connection to the local docker server failed."
        case RUBY_PLATFORM
        when /linux/
          help << "Please make sure the docker daemon is running."
          help << ""
          help << "On Ubuntu/Debian:"
          help << "   sudo service docker start"
          help << ""
          help << "On Fedora/Centos/RHEL"
          help << "   sudo systemctl start docker"
          help << ""
          help << "On SuSE"
          help << "   sudo systemctl start docker"
          help << ""
          help << "And re-check with 'docker version'"
        else
          help << "    Please check why 'docker version' fails."
        end
      elsif !ok? && !b2d_avail?
        case RUBY_PLATFORM
        when /mingw|mswin/
          help << "Docker is not available. Please download and install boot2docker:"
          help << "   https://github.com/boot2docker/windows-installer/releases"
        when /linux/
          help << "Docker is not available."
          help << ""
          help << "Install on Ubuntu/Debian:"
          help << "   sudo apt-get install docker.io"
          help << ""
          help << "Install on Fedora/Centos/RHEL"
          help << "   sudo yum install docker"
          help << "   sudo systemctl start docker"
          help << ""
          help << "Install on SuSE"
          help << "   sudo zypper install docker"
          help << "   sudo systemctl start docker"
        when /darwin/
          help << "Docker is not available. Please download and install boot2docker:"
          help << "   https://github.com/boot2docker/osx-installer/releases"
        else
          help << "Docker is not available."
        end
      elsif !ok? && !b2d_init_ok?
        help << "boot2docker is installed but couldn't be initialized."
        help << ""
        help << "    Please check why 'boot2docker init' fails."
      elsif !ok? && !b2d_start_ok?
        help << "boot2docker is installed but couldn't be started."
        help << ""
        help << "    Please check why 'boot2docker start' fails."
      elsif !ok? && b2d_start_ok?
        help << "boot2docker is installed and started, but 'docker version' failed."
        help << ""
        help << "    Please check why 'docker version' fails."
      end

      help.join("\n")
    end
  end
end
