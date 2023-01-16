# Contributing

This document is intended for the rake-compiler-dock contributors.

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

The cache will be generated in a sibling directory ("../rake-compiler-dock-cache") to avoid including the cache in the build context.
