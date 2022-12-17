#!/bin/bash

set -exuo pipefail
IFS=$'\n\t'

main() {
  local to_uninstall=()

  if ! command -v dpkg-architecture; then
    echo "dpkg-architecture not found, installing" >&2
    apt-get -qq -y update
    apt-get -qq -y install --no-install-recommends debhelper lsb-release
    rm -rf /var/lib/apt/lists/*
    to_uninstall+=("debhelper" "lsb-release")
  fi

  deb_host_arch="$(dpkg-architecture --query DEB_HOST_ARCH)"
  deb_target_arch="$1"

  if [ "$deb_target_arch" != "$deb_host_arch" ]; then
    echo "Setting up multiarch support for $deb_target_arch" >&2

    # Add arch support for target so we can install libs
    dpkg --add-architecture "$deb_target_arch"
    # Qualify our current source lists to make sure debian doesn't infer stuff
    sed -i "s/^deb http/deb [arch=$deb_host_arch] http/" /etc/apt/sources.list
    # Add sources for ported target libs
    sh -c "echo \"deb [arch=$deb_target_arch] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -cs) main universe restricted multiverse\" >> /etc/apt/sources.list"
    sh -c "echo \"deb [arch=$deb_target_arch] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -cs)-updates main universe restricted multiverse\" >> /etc/apt/sources.list"
    sh -c "echo \"deb [arch=$deb_target_arch] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -cs)-security main universe restricted multiverse\" >> /etc/apt/sources.list"
    apt-get update
  else
    echo "No need to set up multiarch support for $deb_target_arch"
  fi

  if [ "${#to_uninstall[@]}" -gt 0 ]; then
    apt-get remove -y "${to_uninstall[@]}"
  fi

  rm "$0"
}

main "$@"
