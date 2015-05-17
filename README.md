# rake-compiler-dock

A docker image for using rake-compiler.

This is similair to [rake-compiler-dev-box](https://github.com/tjschuck/rake-compiler-dev-box) but is based on lightwight Docker containers and is wrapped as a gem for easier usage.

## Installation

Install it as prebuilt docker image:

    $ sudo apt-get install docker.io
    $ gem install rake-compiler-dock

... or build your own image:

    $ sudo apt-get install docker.io
    $ git clone https://github.com/larskanis/rake-compiler-dock
    $ rake install

## Usage

`rake-compiler-dock` can be used to issue commands within the docker image. The first run will download the image.
It mounts the current directory into the docker environment and makes sure, that all commands are executed with the host user and group permissions.

To build win32/win64 binary gems, it is typically called like this:

    $ cd your-gem-dir/
    $ rake-compiler-dock /usr/local/rvm/wrappers/ruby-2.2.2/rake cross native gem RUBY_CC_VERSION=1.9.3:2.0.0:2.1.6:2.2.2

The versions in `RUBY_CC_VERSION` must match the cross ruby versions in the docker image.

A java gem can be built per:
    $ cd your-gem-dir/
    $ rake-compiler-dock /usr/local/rvm/wrappers/jruby-1.7.19/rake gem

## Contributing

1. Fork it ( https://github.com/larskanis/rake-compiler-dock/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
