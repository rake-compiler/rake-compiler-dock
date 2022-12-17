#!/bin/bash

set -exuo pipefail
IFS=$'\n\t'

main() {
  deb_host_arch="$(dpkg --print-architecture)"
  deb_target_arch="$1"

  shift

  cross_packages=()
  packages=("$@")

  if [ "$deb_target_arch" != "$deb_host_arch" ] && [ "$deb_target_arch" = "arm64" ]; then
    echo "Setting up multiarch support for $deb_target_arch" >&2
    dpkg --add-architecture "$deb_target_arch"
    cross_packages=("${packages[@]/%/:$deb_target_arch}")
  else
    echo "No need to set up multiarch support for $deb_target_arch"
  fi

  apt-get -qq -y update
  apt-get -qq -y install "${packages[@]}" "${cross_packages[@]}"
  rm -rf /var/lib/apt/lists/*

  rm "$0"
}

main "$@"
