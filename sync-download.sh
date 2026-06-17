#!/bin/bash

set -e

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

mkdir -p .download

./build.sh download --build-arg CACHE_BUST="$(date)"
trap "docker rmi -f download:cache >/dev/null || :" EXIT

docker run --rm -v ./.download/:/download download:cache

rm -f build-download.log
ls -l .download
