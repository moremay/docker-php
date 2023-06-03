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

docker build . -t temp "$@"

if [ -z "$isapp" ]; then
  docker run --rm -v ./:/tmp/host temp /bin/sh -c "cp -uv /usr/local/etc/php/php.ini /tmp/host/php.ini"
fi

tags=($ver)
if [ -x "tags.sh" ]; then
  tags=("${tags[@]}" $(./tags.sh))
elif [ -f "tags" ]; then
  tags=("${tags[@]}" $(cat tags))
else
  [ "${ver/-/}" == "$ver" ] && tags=("${tags[@]}" "$ver-alpine")
fi

names=()
for tag in "${tags[@]}"; do
  name="${user}php:$tag"
  [ "${tag/:/}" == "$tag" ] || name="${user}$tag"
  names=("${names[@]}" $name)
  docker tag temp $name
done

docker rmi temp

echo -e "\033[36;1m>>> ${names[@]}\033[0m"
