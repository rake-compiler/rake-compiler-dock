#!/bin/bash

set -exuo pipefail
IFS=$'\n\t'

main() {
  deb_host_arch="$(dpkg --print-architecture)"
  lsb_release="$(grep VERSION_CODENAME < /etc/os-release | cut -d= -f2 | tr -d '"')"
  deb_target_arch="$1"

  shift

  cross_packages=()
  packages=("$@")

  if [ "$deb_target_arch" != "$deb_host_arch" ] && [ "$deb_target_arch" = "arm64" ]; then
    echo "Setting up multiarch support for $deb_target_arch" >&2
    dpkg --add-architecture "$deb_target_arch"
    cross_packages=("${packages[@]/%/:$deb_target_arch}")

    # Qualify our current source lists to make sure debian doesn't infer stuff
    sed -i "s/^deb http/deb [arch=$deb_host_arch] http/" /etc/apt/sources.list

    # Add sources for ported target libs
    echo "deb [arch=$deb_target_arch] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -cs) main universe restricted multiverse"
    echo "deb [arch=$deb_target_arch] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -cs)-updates main universe restricted multiverse"
    echo "deb [arch=$deb_target_arch] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -cs)-security main universe restricted multiverse"
  else
    echo "No need to set up multiarch support for $deb_target_arch"
  fi

  apt-get -qq -y update
  apt-get -qq -y install "${packages[@]}" "${cross_packages[@]}"
  rm -rf /var/lib/apt/lists/*

  rm "$0"
}

main "$@"
