# rake-compiler-dock

Easy to use Docker based cross compiler environment for building binary windows gems.

This is similar to [rake-compiler-dev-box](https://github.com/tjschuck/rake-compiler-dev-box) but is based on lightweight Docker containers and is wrapped as a gem for easier usage and integration.


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

`rake-compiler-dock` can be used to issue commands within the docker image.
It mounts the current working directory into the docker environment.
All commands are executed with the current user and group of the host.

`rake-compiler-dock` without arguments starts an interactive shell session.
You can choose between different ruby versions by `rvm use <version>` .
All changes within the current working directory are shared with the host.
But note, that all other changes to the file system are dropped at the end of the session.

`rake-compiler-dock` can also take the build command(s) from STDIN or as command arguments.

To build x86- and x64 Windows (Mingw) binary gems, it is typically called like this:

    $ cd your-gem-dir/
    $ rake-compiler-dock bash -c "bundle && rake cross native gem RUBYOPT=--disable-rubygems"

The installed cross rubies can be listed like this:

    $ rake-compiler-dock bash -c 'rvmsudo rake-compiler update-config'

The environment variable `RUBY_CC_VERSION` is predefined and includes all these versions:

    $ rake-compiler-dock bash -c 'echo $RUBY_CC_VERSION'    # =>  1.8.7:1.9.3:2.0.0:2.1.6:2.2.2

Overwrite `RUBY_CC_VERSION`, if your gem does not support all available versions.

### Add to your Rakefile

Rake-compiler-dock can be easily integrated into your Rakefile like this:

    task 'gem:windows' do
      require 'rake_compiler_dock'
      RakeCompilerDock.sh "bundle && rake cross native gem"
    end

See [the wiki](https://github.com/larskanis/rake-compiler-dock/wiki) for projects which use rake-compiler-dock.

## Contributing

1. Fork it ( https://github.com/larskanis/rake-compiler-dock/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
