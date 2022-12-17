#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# A script to build and push a multi-arch image to Docker Hub, based on
# https://github.com/pypa/manylinux/issues/1306

repo="${DOCKERHUB_USER:-larskanis}"
tags=("latest" "2022-12-11-145d107")
base_images=("manylinux2014" "manylinux_2_24")

for base_image in "${base_images[@]}"; do
  for tag in "${tags[@]}"; do
    echo Re-manifesting "$base_image":"$tag" >&2

    docker pull --quiet quay.io/pypa/"$base_image"_aarch64:"$tag"
    docker pull --quiet quay.io/pypa/"$base_image"_x86_64:"$tag"

    docker tag quay.io/pypa/"$base_image"_x86_64:"$tag" "$repo"/"$base_image"_x86_64:"$tag"
    docker tag quay.io/pypa/"$base_image"_aarch64:"$tag" "$repo"/"$base_image"_aarch64:"$tag"

    docker push --quiet "$repo"/"$base_image"_x86_64:"$tag"
    docker push --quiet "$repo"/"$base_image"_aarch64:"$tag"

    docker manifest create "$repo"/"$base_image":"$tag" \
      --amend "$repo"/"$base_image"_x86_64:"$tag" \
      --amend "$repo"/"$base_image"_aarch64:"$tag"

    docker manifest push "$repo"/"$base_image":"$tag"
  done
done
