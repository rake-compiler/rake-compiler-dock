# rake-compiler-dock

A docker image for using rake-compiler.

This is similar to [rake-compiler-dev-box](https://github.com/tjschuck/rake-compiler-dev-box) but is based on lightweight Docker containers and is wrapped as a gem for easier usage.

## Installation

Make sure docker is installed:

    $ sudo apt-get install docker.io

Install rake-compiler-dock as a gem. The docker image is downloaded at the first run:

    $ gem install rake-compiler-dock

... or build your own gem and docker image:

    $ git clone https://github.com/larskanis/rake-compiler-dock
    $ rake install

## Usage

`rake-compiler-dock` can be used to issue commands within the docker image.
It mounts the current directory into the docker environment.
All commands are executed with the user and group of the host.

`rake-compiler-dock` without arguments starts an interactive shell session.
You can choose between different ruby versions by `rvm use <version>` .
All changes within the current working directory are shared with the host.
All other changes to the file system are dropped at the end of the session.

`rake-compiler-dock` can also take the build command(s) from STDIN or as command arguments.

To build win32/win64 binary gems, it is typically called like this:

    $ cd your-gem-dir/
    $ rake-compiler-dock /usr/local/rvm/wrappers/2.2/rake cross native gem RUBYOPT=--disable-rubygems

The environment variable `RUBY_CC_VERSION` is predefined and includes all Mingw versions of ruby from 1.8.7 to 2.2.

A java gem can be built per:

    $ cd your-gem-dir/
    $ rake-compiler-dock /usr/local/rvm/wrappers/jruby/rake gem

If your Rakefile requires additional gems, you can install them as specified in your Gemfile:

    $ rake-compiler-dock bash -c "rvm use jruby && bundle && rake gem"

## Contributing

1. Fork it ( https://github.com/larskanis/rake-compiler-dock/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
