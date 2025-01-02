# Contributing

This document is intended for the rake-compiler-dock contributors.

## Cutting a release

- prep
  - [ ] make sure CI is green!
  - [ ] update `History.md` and `lib/rake_compiler_dock/version.rb`
- build
  - [ ] run the steps below to generate the images locally
  - [ ] run `gem build rake-compiler-dock`
  - [ ] create a git tag
- push
  - [ ] run `bundle exec rake release:images`
  - [ ] run `gem push pkg/rake-compiler-dock*gem`
  - [ ] run `git push && git push --tags`
- announce
  - [ ] create a release at https://github.com/rake-compiler/rake-compiler-dock/releases


## Building a versioned image

We want to preserve the cache if we can, so patch releases don't change _all_ the layers. There are a few ways to do this.


### Using local docker

If you're going to keep your local docker cache, around, you can run things in parallel:

```
bundle exec rake build
```


### Use a custom docker command

If you're a pro and want to run a custom command and still run things in parallel:

```
export RCD_DOCKER_BUILD="docker build --arg1 --arg2"
bundle exec rake build
```


### Using the buildx backend and cache

Here's one way to leverage the buildx cache, which will turn off parallel builds but generates an external cache directory that can be saved and re-used:

```
export RCD_USE_BUILDX_CACHE=t
docker buildx create --use --driver=docker-container
bundle exec rake build
```


### Create builder instance for two architectures

Building with qemu emulation fails currently with a segfault, so that it must be built by a builder instance with at least one remote node for the other architecture.
Building on native hardware is also much faster (~45 minutes) than on qemu.
A two-nodes builder requires obviously a ARM and a Intel/AMD device.
It can be created like this:

```sh
# Make sure the remote instance can be connected
$ docker -H ssh://isa info

# Create a new builder with the local instance
# Disable the garbage collector by the config file
$ docker buildx create --name isayoga --config build/buildkitd.toml

# Add the remote instance
$ docker buildx create --name isayoga --config build/buildkitd.toml --append ssh://isa

# They are inactive from the start
$ docker buildx ls
NAME/NODE      DRIVER/ENDPOINT                   STATUS     BUILDKIT   PLATFORMS
isayoga        docker-container
 \_ isayoga0    \_ unix:///var/run/docker.sock   inactive
 \_ isayoga1    \_ ssh://isa                     inactive
default*       docker
 \_ default     \_ default                       running    v0.13.2    linux/arm64

# Bootstrap the instances
$ docker buildx inspect --bootstrap --builder isayoga

# Set the new builder as default
$ docker buildx use isayoga

# Now it should be default and in state "running"
$ docker buildx ls
NAME/NODE      DRIVER/ENDPOINT                   STATUS    BUILDKIT   PLATFORMS
isayoga*       docker-container
 \_ isayoga0    \_ unix:///var/run/docker.sock   running   v0.18.2    linux/arm64
 \_ isayoga1    \_ ssh://isa                     running   v0.18.2    linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386
default        docker
 \_ default     \_ default                       running   v0.13.2    linux/arm64
```
