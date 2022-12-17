#!/bin/bash

set -exuo pipefail
IFS=$'\n\t'

main() {
  deb_host_arch="$(dpkg --print-architecture)"
  deb_target_arch="$1"

  shift

  packages=("$@")

  if [ "$deb_target_arch" != "$deb_host_arch" ]; then
    echo "Setting up multiarch support for $deb_target_arch" >&2
    dpkg --add-architecture "$deb_target_arch"
    packages=("${packages[@]/%/:$deb_target_arch}")
  else
    echo "No need to set up multiarch support for $deb_target_arch"
  fi

  apt-get -qq -y update
  apt-get -qq -y install "${packages[@]}"
  rm -rf /var/lib/apt/lists/*

  rm "$0"
}

main "$@"
