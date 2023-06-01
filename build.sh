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

isapp=
isapp=$(echo "$ver" | grep -wqs "^[1-9]" || echo 'yes')

user=$(docker info | grep 'Username' | awk '{print $2}')
[ -z "$user" ] || user="$user/"

if [ -f "tags" ]; then
  tags=($(cat tags))
  for tag in "${tags[@]}"; do
    set -- -t ${user}php:$tag "$@"
  done
elif [ "${ver/-/}" == "$ver" ]; then
  set -- -t ${user}php:$ver-alpine "$@"
fi

name=${user}php:$ver
set -- -t $name "$@"

docker build . "$@"

if [ -z "$isapp" ]; then
  docker run --rm -v ./:/tmp/host $name /bin/sh -c "cp -uv /usr/local/etc/php/php.ini /tmp/host/php.ini"
fi
