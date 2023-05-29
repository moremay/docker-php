#!/bin/bash

set -e

if [ -z "$1" ]; then
  if [ -f "Dockerfile" ]; then
    ver="$(basename $(pwd))"
  fi
elif [ -d "$1" ]; then
  ver="$1"
  pushd "$ver" >/dev/null
  shift
fi

if [ -z "$ver" ]; then
  ver="8.2"
  pushd "$ver" >/dev/null
fi

user=$(docker info | grep 'Username' | awk '{print $2}')
[ -z "$user" ] || user="$user/"

name=${user}php:$ver
set -- -t $name "$@"

if [ "${name/-/}" == "$name" ]; then
  name="$name-alpine"
  set -- -t $name "$@"
fi

docker build . "$@"
docker run --rm -v ./:/tmp/host $name /bin/sh -c "cp -uv /usr/local/etc/php/php.ini /tmp/host/php.ini"
