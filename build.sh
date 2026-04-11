#!/bin/bash

set -e

usage() {
  echo "Usage: ./build.sh <dirname> [-v|-ver image-tag] [-p|--push] [-t|--test] [-m|--mirrors] [buildx options]"
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
CLEAR_BUILDX=
PUSH=
params=("-f" "$work/Dockerfile")

if [ -f "$work/tag" ]; then
  tag_tmp=$(< "$work/tag")
  test -n "$tag_tmp" && IMAGE_TAG="$tag_tmp"
fi

shift
while [ $# -gt 0 ]; do
  case $1 in
  -m|--mirrors)
    params=("${params[@]}" --build-arg mirrors=mirrors.nju.edu.cn)
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
  -c|--clear)
    CLEAR_BUILDX="yes"
    ;;
  *)
    params=("${params[@]}" "$1")
    ;;
  esac
  shift
done

#echo "Enter $work"
#pushd "$work" >/dev/null
#trap "echo Leave $work; popd >/dev/null" EXIT

user=$(docker info | grep 'Username' | awk '{print $2}')
[ -z "$user" ] || user="$user/"

if [ "$IMAGE_TAG" != "${IMAGE_TAG%%:*}" ]; then
  IMAGE_REPO="${IMAGE_TAG%%:*}"
  IMAGE_TAG="${IMAGE_TAG//*:}"
fi

default_image="${user}${IMAGE_REPO}:$IMAGE_TAG"
images="-t $default_image"
if [ -f "$work/.latest" ]; then
    images="$images -t ${user}${IMAGE_REPO}:${IMAGE_TAG%%.*}"
fi

#cp -uvf ../script/* .
#test -d x86_64 || ln -rs ../apk/x86_64 x86_64

instance_name=provenance-builder

if docker buildx ls | grep -qs "$instance_name"; then
  if [ -n "$CLEAR_BUILDX" ]; then
    docker buildx prune -af || :
  fi
  docker buildx use $instance_name
else
  docker buildx create --name $instance_name --use
fi

if [ -n "$PUSH" ]; then
  docker buildx build . --provenance=mode=max --sbom=true --push $images "${params[@]}"
fi
docker buildx build . --load $images "${params[@]}"

#rm -rf ./docker-*

if [ -n "$TEST_WEB" ]; then
  docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v ~/trivy-cache:/root/.cache/ aquasec/trivy image $default_image
  "$BIN_DIR/test.sh" $default_image
fi

echo -e "\033[36;1m>>> $(echo "$images" | sed 's/-t //g')\033[0m"
