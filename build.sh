#!/bin/bash

set -e

usage() {
  echo "Usage: ./build.sh <dirname> [-v|-ver image-tag] [-p|--push] [-t|--test] [--ali] [buildx options]"
}

work="$1"
if [[ -z "$work" || ! -d "$work" ]]; then
  usage
  exit 1
fi

if [ ! -f "$work/Dockerfile" ]; then
  echo "Not docker : '$work/Dockerfile' not exist"
  exit 1
fi

BIN_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
IMAGE_REPO="php"
IMAGE_TAG="$work"
TEST_WEB=
PUSH=
params=()

if [ -f "$work/tag" ]; then
  tag_tmp=$(< "$work/tag")
  test -n "$tag_tmp" && IMAGE_TAG="$tag_tmp"
fi

shift
while [ $# -gt 0 ]; do
  case $1 in
  --ali)
    params=("${params[@]}" --build-arg mirrors=mirrors.aliyun.com --build-arg gnu_mirrors=https://mirrors.aliyun.com/gnu)
    ;;
  -p|--push)
    PUSH=yes
    ;;
  -v|--ver)
    shift
    IMAGE_TAG="$1"
    if [[ -z "$IMAGE_TAG" || '-' == "${IMAGE_TAG:0:1}" ]]; then
      echo "--ver does not specify a tag"
      exit 1
    fi
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
  docker buildx create --name provenance-builder --use || :
  docker buildx build . --provenance=mode=max --sbom=true --push $images "${params[@]}"
  #docker buildx rm provenance-builder
else
  docker buildx use default
  docker buildx build . $images "${params[@]}"
fi

rm -rf ./docker-* ./x86_64

if [ -n "$TEST_WEB" ]; then
  docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v ~/trivy-cache:/root/.cache/ aquasec/trivy image $default_image
  "$BIN_DIR/test.sh" $default_image
fi

echo -e "\033[36;1m>>> $(echo "$images" | sed 's/-t //')\033[0m"
