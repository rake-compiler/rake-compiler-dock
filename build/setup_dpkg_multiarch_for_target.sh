#!/bin/bash

set -exuo pipefail
IFS=$'\n\t'

main() {
  deb_host_arch="$(dpkg --print-architecture)"
  deb_target_arch="$1"

  if [ "$deb_target_arch" != "$deb_host_arch" ]; then
    echo "Setting up multiarch support for $deb_target_arch" >&2

    dpkg --add-architecture "$deb_target_arch"
    apt-get -qq -y update
  else
    echo "No need to set up multiarch support for $deb_target_arch"
  fi

  rm "$0"
}

main "$@"
