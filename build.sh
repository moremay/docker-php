#!/bin/bash

set -e

if [[ -n "$1" && -d "$1" ]]; then
  ver="$1"
  work="$(pwd)/$1"
  shift
elif [ -f "Dockerfile" ]; then
  ver="$(basename $(pwd))"
  work="$(pwd)"
fi

PUSH=
params=()
while [ $# -gt 0 ]; do
  case $1 in
  --ali)
    params=("${params[@]}" --build-arg mirrors=mirrors.aliyun.com)
    ;;
  -c|--composer)
    params=("${params[@]}" --build-arg composer=yes)
    ;;
  -p)
    PUSH=yes
    ;;
  -v|--ver)
    shift
    ver="$1"
    ;;
  *)
    params=("${params[@]}" "$1")
    ;;
  esac
  shift
done

if [ -z "$ver" ]; then
  ver="8.4"
fi

if [ -z "$work" ]; then
  work="$(dirname $(dirname "$(realpath "${BASH_SOURCE[0]}")"))/$ver"
fi
if [ ! -d "$work" ]; then
  echo "NOT EXISTS: '#work'"
  exit 1
fi

echo "Enter $work"
pushd "$work" >/dev/null
trap "echo Leave $work; popd >/dev/null" EXIT

user=$(docker info | grep 'Username' | awk '{print $2}')
[ -z "$user" ] || user="$user/"

docker build . -t temp "${params[@]}"

images=()

if [ -x "tags.sh" ]; then
  images=($(./tags.sh))
else
  image_name="php"
  plat="${ver/*-/}"
  ver="${ver/-*/}"
  [ "$plat" == "$ver" ] && plat=

  composer=($(docker run --rm temp /bin/sh -c "composer --version 2>/dev/null || true" | grep ' version ' || true))
  composer=${composer[2]}
  if [ -n "$composer" ]; then
    image_name="${image_name}-composer"
    ver="$ver-$composer"
  fi

  if [ "$plat" == "" ]; then
    images=("${image_name}:$ver" "${image_name}:$ver-alpine")
  else
    images=("${image_name}:$ver-$plat")
  fi
fi

names=()
for image in "${images[@]}"; do
  name="${user}$image"
  names=("${names[@]}" $name)
  docker tag temp $name
  if [ -n "$PUSH" ]; then
    docker push $name
  fi
done

docker rmi temp

echo -e "\033[36;1m>>> ${names[@]}\033[0m"
