#!/bin/bash

set -e

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

docker run -d --rm -v ./apk:/usr/src/repo --name tmp-alpine alpine sleep infinity
trap "docker stop tmp-alpine" EXIT

docker exec tmp-alpine sh -c "
cp -f /usr/src/repo/.abuild/*.pub /etc/apk/keys/
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
echo '/usr/src/repo/' >> /etc/apk/repositories
apk update
"

get_ver() {
  docker exec tmp-alpine sh -c "apk query --all-matches '$1' | grep Version"
}

echo "=========================="

for pkg in "$@"; do
  echo "$pkg"
  get_ver "$pkg"
  echo "=========================="
done
