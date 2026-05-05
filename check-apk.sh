#!/bin/bash

set -e

docker run -d --rm --name tmp-alpine --entrypoint /bin/sh alpine -c "sleep infinity"
trap "docker stop tmp-alpine" EXIT

docker exec -i tmp-alpine sh -c "
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories
apk update
"

get_ver() {
  docker exec -i tmp-alpine sh -c "apk query --all-matches '$1' | grep Version"
}

for pkg in "$@"; do
  echo "$pkg"
  get_ver "$pkg"
done
