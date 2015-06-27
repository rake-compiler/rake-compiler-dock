0.4.0 / 2015-06-29
------------------
* Add support for OS-X.
* Fix usage of STDIN for sending data/commands into the container.
* Limit to ruby-1.9.3 or newer.
* Allow spaces in user name and path on the host side.


0.3.1 / 2015-06-24
------------------
* Add :sigfw and :runas options.
* Don't stop the container on Ctrl-C when running interactively.
* Workaround an issue with sendfile() leading to broken files when using boot2docker on Windows.


0.3.0 / 2015-06-17
------------------
* Workaround an issue with broken DLLs when building on Windows.
* Print docker command line based on verbose flag of rake.
* Add check for docker and instructions for install.


0.2.0 / 2015-06-08
------------------
* Add a simple API for running commands within the rake-compiler-dock environment.
* Respect ftp, http and https_proxy settings from the host.
* Add wget to the image


0.1.0 / 2015-05-27
------------------
* first public release
