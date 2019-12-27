require "shellwords"
require "etc"
require "rake_compiler_dock/version"

module RakeCompilerDock
  class DockerIsNotAvailable < RuntimeError
  end

  class Starter
    class << self
      def sh(cmd, options={}, &block)
        exec('bash', '-c', cmd, options, &block)
      end

      def exec(*args)
        options = (Hash === args.last) ? args.pop : {}

        mountdir = options.fetch(:mountdir){ ENV['RCD_MOUNTDIR'] || Dir.pwd }
        workdir = options.fetch(:workdir){ ENV['RCD_WORKDIR'] || Dir.pwd }
        case RUBY_PLATFORM
        when /mingw|mswin/
          mountdir = sanitize_windows_path(mountdir)
          workdir = sanitize_windows_path(workdir)
          # Virtualbox shared folders don't care about file permissions, so we use generic ids.
          uid = 1000
          gid = 1000
        when /darwin/
          uid = 1000
          gid = 1000
        else
          # Docker mounted volumes also share file uid/gid and permissions with the host.
          # Therefore we use the same attributes inside and outside the container.
          uid = Process.uid
          gid = Process.gid
        end
        user = options.fetch(:username){ current_user }
        group = options.fetch(:groupname){ current_group }
        rubyvm = options.fetch(:rubyvm){ ENV['RCD_RUBYVM'] } || "mri"

        platforms = options.fetch(:platform){ ENV['RCD_PLATFORM'] } || "x86-mingw32 x64-mingw32"
        platforms.split(" ").each do |platform|
          image_name = options.fetch(:image) do
            platform_postfix = rubyvm.to_s == "jruby" ? "" : "-#{platform}"
            ENV['RCD_IMAGE'] ||
                ENV['RAKE_COMPILER_DOCK_IMAGE'] ||
                "larskanis/rake-compiler-dock-#{rubyvm}#{platform_postfix}:#{IMAGE_VERSION}"
          end

          check = check_docker(mountdir) if options.fetch(:check_docker){ true }
          docker_opts = options.fetch(:options) do
            opts = ["--rm", "-i"]
            opts << "-t" if $stdin.tty?
            opts
          end

          if verbose_flag(options) && args.size == 3 && args[0] == "bash" && args[1] == "-c"
            $stderr.puts "rake-compiler-dock bash -c #{ args[2].inspect }"
          end

          runargs = args.dup
          runargs.unshift("sigfw") if options.fetch(:sigfw){ true }
          runargs.unshift("runas") if options.fetch(:runas){ true }

          cmd = [check.docker_command, "run",
              "-v", "#{mountdir}:#{make_valid_path(mountdir)}",
              "-e", "UID=#{uid}",
              "-e", "GID=#{gid}",
              "-e", "USER=#{user}",
              "-e", "GROUP=#{group}",
              "-e", "ftp_proxy",
              "-e", "http_proxy",
              "-e", "https_proxy",
              "-e", "RCD_HOST_RUBY_PLATFORM=#{RUBY_PLATFORM}",
              "-e", "RCD_HOST_RUBY_VERSION=#{RUBY_VERSION}",
              "-e", "RCD_IMAGE=#{image_name}",
              "-w", make_valid_path(workdir),
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
      end

      def verbose_flag(options)
        options.fetch(:verbose) do
          Object.const_defined?(:Rake) && Rake.const_defined?(:FileUtilsExt) ? Rake::FileUtilsExt.verbose_flag : false
        end
      end

      def current_user
        make_valid_user_name(Etc.getlogin)
      end

      def current_group
        group_obj = Etc.getgrgid rescue nil
        make_valid_group_name(group_obj ? group_obj.name : "dummygroup")
      end

      def make_valid_name(name)
        name = name.to_s.downcase
        name = "_" if name.empty?
        # Convert disallowed characters
        if name.length > 1
          name = name[0..0].gsub(/[^a-z_]/, "_") + name[1..-2].to_s.gsub(/[^a-z0-9_-]/, "_") + name[-1..-1].to_s.gsub(/[^a-z0-9_$-]/, "_")
        else
          name = name.gsub(/[^a-z_]/, "_")
        end

        # Limit to 32 characters
        name.sub( /^(.{16}).{2,}(.{15})$/ ){ $1+"-"+$2 }
      end

      def make_valid_user_name(name)
        name = make_valid_name(name)
        PredefinedUsers.include?(name) ? make_valid_name("_#{name}") : name
      end

      def make_valid_group_name(name)
        name = make_valid_name(name)
        PredefinedGroups.include?(name) ? make_valid_name("_#{name}") : name
      end

      def make_valid_path(name)
        # Convert problematic characters
        name = name.gsub(/[ ]/i, "_")
      end

      @@docker_checked = {}

      def check_docker(pwd)
        @@docker_checked[pwd] ||= begin
          check = DockerCheck.new($stderr, pwd)
          unless check.ok?
            at_exit do
              check.print_help_text
            end
            raise DockerIsNotAvailable, "Docker is not available"
          end
          check
        end
      end

      # Change Path from "C:\Path" to "/c/Path" as used by boot2docker
      def sanitize_windows_path(path)
        path.gsub(/^([a-z]):/i){ "/#{$1.downcase}" }
      end
    end
  end
end
