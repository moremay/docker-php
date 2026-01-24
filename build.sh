#!/bin/bash

set -e

BIN_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
IMAGE_REPO="php"
IMAGE_TAG=
TEST_WEB=

if [[ -n "$1" && "${1:0,1}" != "-" ]]; then
  IMAGE_TAG="$1"
  work="$(pwd)/$1"
  shift
elif [ -f "Dockerfile" ]; then
  IMAGE_TAG="$(basename $(pwd))"
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
    IMAGE_TAG="$1"
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

if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG="8.5"
fi

if [ -z "$work" ]; then
  work="$BIN_DIR/$IMAGE_TAG"
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

default_image="${user}${IMAGE_REPO}:$IMAGE_TAG"
images="-t $default_image"
if [ -f .latest ]; then
    images="$images -t ${user}${IMAGE_REPO}:${IMAGE_TAG%%.*}"
fi

if [ -n "$PUSH" ]; then
  export DOCKER_BUILDKIT=1
  docker buildx create --name provenance-builder --use || :
  docker buildx build . --provenance=mode=max --sbom=true --push $images "${params[@]}"
else
  docker build . $images "${params[@]}"
fi

rm -rf ./docker-* ./x86_64

if [ -n "$TEST_WEB" ]; then
  docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v ~/trivy-cache:/root/.cache/ aquasec/trivy image $default_image
  "$BIN_DIR/test.sh" $default_image
fi

echo -e "\033[36;1m>>> ${images}\033[0m"
