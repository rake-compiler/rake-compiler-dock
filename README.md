# rake-compiler-dock

Easy to use Docker based cross compiler environment for building binary Windows gems.

It provides cross compilers and Ruby environments for all versions of the [RubyInstaller](http://rubyinstaller.org/) .
They are prepared for use with [rake-compiler](https://github.com/rake-compiler/rake-compiler) .

This is similar to [rake-compiler-dev-box](https://github.com/tjschuck/rake-compiler-dev-box) but is based on lightweight Docker containers and is wrapped as a gem for easier setup, usage and integration.
It is also a bit more reliable, since the underlying docker images are versioned and kept unchanged while building.

## Installation

Install docker natively on Linux:

    $ sudo apt-get install docker.io

... or install boot2docker on [Windows](https://github.com/boot2docker/windows-installer/releases) or [OS X](https://github.com/boot2docker/osx-installer/releases) .

Install rake-compiler-dock as a gem. The docker image is downloaded later on demand:

    $ gem install rake-compiler-dock

... or build your own gem and docker image:

    $ git clone https://github.com/larskanis/rake-compiler-dock
    $ rake install


## Usage

Rake-compiler-dock offers the shell command `rake-compiler-dock` and a [ruby API for issuing commands within the docker image](http://www.rubydoc.info/gems/rake-compiler-dock/RakeCompilerDock) described below.

`rake-compiler-dock` without arguments starts an interactive shell session.
This is best suited to try out and debug a build.
It mounts the current working directory into the docker environment.
All changes below the current working directory are shared with the host.
But note, that all other changes to the file system of the container are dropped at the end of the session - the docker image is stateless. `rake-compiler-dock` can also take the build command(s) from STDIN or as command arguments.

All commands are executed with the same user and group of the host.
This is done by copying user account data into the container and sudo to it.

To build x86- and x64 Windows (RubyInstaller) binary gems, it is typically called like this:

    user@host:$ cd your-gem-dir/
    user@host:$ rake-compiler-dock   # this enters a container with an interactive shell
    user@5b53794ada92:$ bundle
    user@5b53794ada92:$ rake cross native gem

The installed cross rubies can be listed like this:

    $ rake-compiler-dock bash -c 'rvmsudo rake-compiler update-config'

The environment variable `RUBY_CC_VERSION` is predefined and includes all these cross ruby versions:

    $ rake-compiler-dock bash -c 'echo $RUBY_CC_VERSION'    # =>  1.8.7:1.9.3:2.0.0:2.1.6:2.2.2

Overwrite `RUBY_CC_VERSION`, if your gem does not support all available versions.

You can also choose between different executable ruby versions by `rvm use <version>` . Current default is 2.2.

### Add to your Rakefile

Rake-compiler-dock can be easily integrated into your Rakefile like this:

    task 'gem:windows' do
      require 'rake_compiler_dock'
      RakeCompilerDock.sh "bundle && rake cross native gem"
    end

See [the wiki](https://github.com/larskanis/rake-compiler-dock/wiki/Projects-using-rake-compiler-dock) for projects which use rake-compiler-dock.

## Contributing

1. Fork it ( https://github.com/larskanis/rake-compiler-dock/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
