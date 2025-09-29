#!/bin/bash

set -e

ver=

if [[ -n "$1" && "${1:0,1}" != "-" ]]; then
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
    params=("${params[@]}" --build-arg mirrors=mirrors.aliyun.com --build-arg gnu_mirrors=https://mirrors.aliyun.com/gnu)
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
  work="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/$ver"
fi
if [ ! -d "$work" ]; then
  echo "NOT EXISTS: '$work'"
  exit 1
fi
if [ ! -f "$work/Dockerfile" ]; then
  echo "NOT docker: '$work'"
  exit 1
fi

echo "Enter $work"
pushd "$work" >/dev/null
trap "echo Leave $work; popd >/dev/null" EXIT

cp -uvf ../script/docker-* .

user=$(docker info | grep 'Username' | awk '{print $2}')
[ -z "$user" ] || user="$user/"

docker build . -t temp "${params[@]}"

rm -f ./docker-*

images=()

if [ -x "tags.sh" ]; then
  images=($(./tags.sh))
else
  image_name="php"
  plat="${ver/*-/}"
  ver="${ver/-*/}"
  [ "$plat" == "$ver" ] && plat=

  if [ "$plat" == "" ]; then
    images=("${image_name}:$ver" "${image_name}:$ver-alpine")
  else
    images=("${image_name}:$ver-$plat")
  fi

  if [ -f .latest ]; then
      images=("${images[@]}" "${image_name}:${ver%%.*}")
  fi
fi

names=()
for image in "${images[@]}"; do
  name="${user}$image"
  names=("${names[@]}" $name)
  docker tag temp $name
done

docker rmi temp
if [ -n "$PUSH" ]; then
  docker push ${names[0]//:*} -a
fi

echo -e "\033[36;1m>>> ${names[@]}\033[0m"
