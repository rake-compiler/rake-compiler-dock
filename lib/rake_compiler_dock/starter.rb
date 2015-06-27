require "shellwords"
require "rake_compiler_dock/version"

module RakeCompilerDock
  class DockerIsNotAvailable < RuntimeError
  end

  class Starter
    class << self
      def sh(cmd, options={}, &block)
        if verbose_flag(options)
          $stderr.puts "rake-compiler-dock bash -c #{ cmd.inspect }"
        end
        exec('bash', '-c', cmd, options, &block)
      end

      def image_name
        ENV['RAKE_COMPILER_DOCK_IMAGE'] || "larskanis/rake-compiler-dock:#{VERSION}"
      end

      def exec(*args)
        options = (Hash === args.last) ? args.pop : {}
        runargs = args.dup

        check_docker if options.fetch(:check_docker){ true }
        runargs.unshift("sigfw") if options.fetch(:sigfw){ true }
        runargs.unshift("runas") if options.fetch(:runas){ true }
        docker_opts = options.fetch(:options) do
          opts = ["--rm", "-i"]
          opts << "-t" if $stdin.tty?
          opts
        end

        case RUBY_PLATFORM
        when /mingw|mswin/
          # Change Path from "C:\Path" to "/c/Path" as used by boot2docker
          pwd = Dir.pwd.gsub(/^([a-z]):/i){ "/#{$1.downcase}" }
          # Virtualbox shared folders don't care about file permissions, so we use generic ids.
          uid = 1000
          gid = 1000
        when /darwin/
          pwd = Dir.pwd
          uid = 1000
          gid = 1000
        else
          pwd = Dir.pwd
          # Docker mounted volumes also share file uid/gid and permissions with the host.
          # Therefore we use the same attributes inside and outside the container.
          uid = Process.uid
          gid = Process.gid
        end
        user = make_valid_name(`id -nu`.chomp)
        group = make_valid_name(`id -ng`.chomp)

        cmd = ["docker", "run",
            "-v", "#{pwd}:#{make_valid_path(pwd)}",
            "-e", "UID=#{uid}",
            "-e", "GID=#{gid}",
            "-e", "USER=#{user}",
            "-e", "GROUP=#{group}",
            "-e", "ftp_proxy=#{ENV['ftp_proxy']}",
            "-e", "http_proxy=#{ENV['http_proxy']}",
            "-e", "https_proxy=#{ENV['https_proxy']}",
            "-w", make_valid_path(pwd),
            *docker_opts,
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

      def make_valid_name(name)
        name = name.downcase
        # Convert disallowed characters
        name = name[0..0].gsub(/[^a-z_]/, "_") + name[1..-2].gsub(/[^a-z0-9_-]/, "_") + name[-1..-1].gsub(/[^a-z0-9_$-]/, "_")
        # Limit to 32 characters
        name.sub( /^(.{16}).{2,}(.{15})$/ ){ $1+"-"+$2 }
      end

      def make_valid_path(name)
        # Convert problematic characters
        name = name.gsub(/[ ]/i, "_")
      end

      @@docker_checked = false

      def check_docker
        return if @@docker_checked
        if check_docker_only
          @@docker_checked = true
        elsif try_boot2docker
          @@docker_checked = true
        else
          at_exit do
            print_docker_install
          end
          raise DockerIsNotAvailable, "Docker is not available"
        end
      end

      def check_docker_only
        version_text = `docker version 2>&1` rescue SystemCallError
        $?.exitstatus == 0 && version_text.to_s =~ /version/
      end

      def try_boot2docker
        version_text = `boot2docker version 2>&1` rescue SystemCallError
        if $?.exitstatus == 0 && version_text.to_s =~ /version/
          $stderr.puts
          $stderr.puts "boot2docker is available, but not ready to use. Trying to start."
          start_text = `boot2docker start` rescue SystemCallError
          if $?.exitstatus == 0
            start_text.scan(/(unset |Remove-Item Env:\\)(?<key>.+?)$/) do |r, |
              $stderr.puts "    unset #{key}"
              ENV.delete(key)
            end
            start_text.scan(/(export |\$Env:)(?<key>.+?)(=| = ")(?<val>.*?)(|\")$/) do |key, val|
              ENV[key] = val
              $stderr.puts "    set #{key}=#{val}"
            end
            return check_docker_only
          else
            false
          end
        else
          false
        end
      end
    end

    def print_docker_install
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
  end
end
