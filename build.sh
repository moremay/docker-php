#!/bin/bash

set -e

BIN_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
VER_TAG=
TEST_WEB=

if [[ -n "$1" && "${1:0,1}" != "-" ]]; then
  VER_TAG="$1"
  work="$(pwd)/$1"
  shift
elif [ -f "Dockerfile" ]; then
  VER_TAG="$(basename $(pwd))"
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
    VER_TAG="$1"
    ;;
  -t|--test)
    TEST_WEB="yes"
    ;;
  *)
    params=("${params[@]}" "$1")
    ;;
  esac
  shift
done

if [ -z "$VER_TAG" ]; then
  VER_TAG="8.5"
fi

if [ -z "$work" ]; then
  work="$BIN_DIR/$VER_TAG"
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

cp -uvf ../script/* .
cp -ruvf ../apk/x86_64 .

user=$(docker info | grep 'Username' | awk '{print $2}')
[ -z "$user" ] || user="$user/"

temp_ver=temp
temp_tag=moremay/php:$temp_ver

docker build . -t $temp_tag "${params[@]}"

rm -rf ./docker-* ./x86_64

if [ -n "$TEST_WEB" ]; then
  docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v ~/trivy-cache:/root/.cache/ aquasec/trivy image $temp_tag
  "$BIN_DIR/test.sh" $temp_ver
fi

images=()

if [ -x "tags.sh" ]; then
  images=($(./tags.sh))
else
  image_name="php"
  images=("${image_name}:$VER_TAG")

  if [ -f .latest ]; then
      images=("${images[@]}" "${image_name}:${VER_TAG%%.*}")
  fi
fi

names=()
for image in "${images[@]}"; do
  name="${user}$image"
  names=("${names[@]}" $name)
  docker tag $temp_tag $name
  [ -n "$PUSH" ] && docker push $name || :
done

docker rmi $temp_tag > /dev/null

echo -e "\033[36;1m>>> ${names[@]}\033[0m"
