# rake-compiler-dock

**Easy to use and reliable cross compiler environment for building Windows, Linux and JRuby binary gems.**

It provides cross compilers and Ruby environments for 2.2 and newer versions of the [RubyInstaller](http://rubyinstaller.org/) and Linux runtime environments.
They are prepared for use with [rake-compiler](https://github.com/rake-compiler/rake-compiler).
It is used by [many gems with C or JRuby extentions](https://github.com/rake-compiler/rake-compiler-dock/wiki/Projects-using-rake-compiler-dock).

This is kind of successor of [rake-compiler-dev-box](https://github.com/tjschuck/rake-compiler-dev-box).
It is wrapped as a gem for easier setup, usage and integration and is based on lightweight Docker containers.
It is also more reliable, since the underlying docker images are versioned and immutable.

## Installation

Install docker natively on Linux:

    $ sudo apt-get install docker.io

... or install [docker-toolbox for Windows and OSX](https://www.docker.com/docker-toolbox) or boot2docker on [Windows](https://github.com/boot2docker/windows-installer/releases) or [OS X](https://github.com/boot2docker/osx-installer/releases) .

Install rake-compiler-dock as a gem. The docker image is downloaded later on demand:

    $ gem install rake-compiler-dock

... or build your own gem and docker image:

    $ git clone https://github.com/rake-compiler/rake-compiler-dock
    $ rake install


## Usage

Rake-compiler-dock provides the necessary tools to build Ruby extensions for Windows and Linux written in C and C++ and JRuby written in Java.
It is intended to be used in conjunction with [rake-compiler's](https://github.com/rake-compiler/rake-compiler) cross build capability.
Your Rakefile should enable cross compilation like so:

    Rake::ExtensionTask.new('my_extension', my_gem_spec) do |ext|
      ext.cross_compile = true
      ext.cross_platform = %w[x86-mingw32 x64-mingw32 x86-linux x86_64-linux]
    end

It may also be used to build ffi based binary gems like [libusb](https://github.com/larskanis/libusb), but currently doesn't provide any additional build helpers for this use case, beyond docker invocation and cross compilers.

### Interactive Usage

Rake-compiler-dock offers the shell command `rake-compiler-dock` and a [ruby API](http://www.rubydoc.info/gems/rake-compiler-dock/RakeCompilerDock) for issuing commands within the docker image, described below.

`rake-compiler-dock` without arguments starts an interactive shell session.
This is best suited to try out and debug a build.
It mounts the current working directory into the docker environment.
All changes below the current working directory are shared with the host.
But note, that all other changes to the file system of the container are dropped at the end of the session - the docker image is static for a given version.
`rake-compiler-dock` can also take the build command(s) from STDIN or as command arguments.

All commands are executed with the same user and group of the host.
This is done by copying user account data into the container and sudo to it.

To build x86 and x64 Windows and Linux binary gems interactively, it can be called like this:

    user@host:$ cd your-gem-dir/
    user@host:$ rake-compiler-dock   # this enters a container with an interactive shell
    user@5b53794ada92:$ bundle
    user@5b53794ada92:$ rake cross native gem
    user@5b53794ada92:$ exit
    user@host:$ ls pkg/*.gem
    your-gem-1.0.0.gem  your-gem-1.0.0-x64-mingw32.gem  your-gem-1.0.0-x86-mingw32.gem
    your-gem-1.0.0-x86_64-linux.gem  your-gem-1.0.0-x86-linux.gem

Or non-interactive:

    user@host:$ rake-compiler-dock bash -c "bundle && rake cross native gem"

The environment variable `RUBY_CC_VERSION` is predefined as described [below](#environment-variables).

If necessary, additional software from the Ubuntu repositories can be installed, prior to the build command.
This is local to the running session, only:

    sudo apt-get update && sudo apt-get install your-package

You can also choose between different executable ruby versions by `rvm use <version>` .
The current default is 2.5.

### JRuby support

Rake-compiler-dock offers a dedicated docker image for JRuby.
JRuby doesn't need a complicated cross build environment like C-ruby, but using Rake-compiler-dock for JRuby makes building binary gems more consistent.

To build java binary gems interactively, it can be called like this:

    user@host:$ cd your-gem-dir/
    user@host:$ RCD_RUBYVM=jruby rake-compiler-dock   # this enters a container with an interactive shell
    user@5b53794ada92:$ ruby -v
    jruby 9.2.5.0 (2.5.0) 2018-12-06 6d5a228 OpenJDK 64-Bit Server VM 10.0.2+13-Ubuntu-1ubuntu0.18.04.4 on 10.0.2+13-Ubuntu-1ubuntu0.18.04.4 +jit [linux-x86_64]
    user@5b53794ada92:$ bundle
    user@5b53794ada92:$ rake java gem
    user@5b53794ada92:$ exit
    user@host:$ ls pkg/*.gem
    your-gem-1.0.0.gem  your-gem-1.0.0-java.gem

### Add to your Rakefile

To make the build process reproducible for other parties, it is recommended to add rake-compiler-dock to your Rakefile.
This can be done like this:

    task 'gem:native' do
      require 'rake_compiler_dock'
      sh "bundle package"   # Avoid repeated downloads of gems by using gem files from the host.
      RakeCompilerDock.sh "bundle --local && rake cross native gem"
      RakeCompilerDock.sh "bundle --local && rake java gem", rubyvm: :jruby
    end

Rake-compiler-dock uses [semantic versioning](http://semver.org/), so you should add it into your Gemfile, to make sure, that future changes will not break your build.

    gem 'rake-compiler-dock', '~> 0.7.0'

See [the wiki](https://github.com/rake-compiler/rake-compiler-dock/wiki/Projects-using-rake-compiler-dock) for projects which make use of rake-compiler-dock.


## Environment Variables

Rake-compiler-dock makes use of several environment variables.

The following variables are recognized by rake-compiler-dock:

* `RCD_RUBYVM` - The flavour of docker image to be used.
    Must be one of `mri`, `jruby`.
* `RCD_IMAGE` - The docker image that is downloaded and started.
    Defaults to "larskanis/rake-compiler-dock:IMAGE_VERSION" with an image version that is determined by the gem version.

The following variables are passed through to the docker container without modification:

* `http_proxy`, `https_proxy`, `ftp_proxy` - See [Frequently asked questions](https://github.com/rake-compiler/rake-compiler-dock/wiki/FAQ) for more details.

The following variables are provided to the running docker container:

* `RCD_IMAGE` - The full docker image name the container is running on.
* `RCD_HOST_RUBY_PLATFORM` - The `RUBY_PLATFORM` of the host ruby.
* `RCD_HOST_RUBY_VERSION` - The `RUBY_VERSION` of the host ruby.
* `RUBY_CC_VERSION` - The target ruby versions for rake-compiler.
    The default is defined in the [Dockerfile](https://github.com/rake-compiler/rake-compiler-dock/blob/master/Dockerfile), but can be changed as a parameter to rake.
* `RCD_MOUNTDIR` - The directory which is mounted into the docker container.
    Defaults to pwd.
* `RCD_WORKDIR` - The working directory within the docker container.
    Defaults to pwd.

Other environment variables can be set or passed through to the container like this:

    RakeCompilerDock.sh "rake cross native gem OPENSSL_VERSION=#{ENV['OPENSSL_VERSION']}"


## More information

See [Frequently asked questions](https://github.com/rake-compiler/rake-compiler-dock/wiki/FAQ) and [![Join the chat at https://gitter.im/larskanis/rake-compiler-dock](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/larskanis/rake-compiler-dock?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


## Contributing

1. Fork it ( https://github.com/rake-compiler/rake-compiler-dock/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
