#!/bin/bash

set -eo pipefail

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
  tag_tmp=$(<"$work/tag")
  test -n "$tag_tmp" && IMAGE_TAG="$tag_tmp"
fi

shift
while [ $# -gt 0 ]; do
  case $1 in
  -m | --mirrors)
    params=("${params[@]}" --build-arg mirrors=mirrors.nju.edu.cn)
    ;;
  -p | --push)
    PUSH=yes
    ;;
  -v | --ver)
    shift
    IMAGE_TAG="$1"
    if [[ -z "$IMAGE_TAG" || '-' == "${IMAGE_TAG:0:1}" ]]; then
      echo "--ver does not specify a tag"
      exit 1
    fi
    ;;
  -t | --test)
    TEST_WEB="yes"
    ;;
  -c | --clear)
    CLEAR_BUILDX="yes"
    ;;
  *)
    params=("${params[@]}" "$1")
    ;;
  esac
  shift
done

if [ "$IMAGE_TAG" != "${IMAGE_TAG%:*}" ]; then
  IMAGE_REPO="${IMAGE_TAG%:*}"
  IMAGE_TAG="${IMAGE_TAG##*:}"
fi

if [ "$IMAGE_REPO" != "${IMAGE_REPO##*/}" ]; then
  # 支持没有 user: `/repo:tag`
  user="${IMAGE_REPO%/*}"
  IMAGE_REPO="${IMAGE_REPO##*/}"
else
  user=$(docker info | grep 'Username' | awk '{print $2}' || :)
fi

[ -z "$user" ] || user="$user/"
IMAGE_REPO="${user}${IMAGE_REPO}"

default_image="${IMAGE_REPO}:$IMAGE_TAG"
images="-t $default_image"
if [ -f "$work/.latest" ]; then
  # php:7.4 => php:7
  images="$images -t ${IMAGE_REPO}:${IMAGE_TAG%%.*}"
fi

export BUILDX_BUILDER=provenance-builder
(
  if docker buildx ls | grep -qs "$BUILDX_BUILDER"; then
    docker buildx use $BUILDX_BUILDER
    if [ -n "$CLEAR_BUILDX" ]; then
      docker buildx prune -af || :
    fi
  else
    docker buildx create --name $BUILDX_BUILDER --use
  fi

  if [ -n "$PUSH" ]; then
    docker buildx build . --provenance=mode=max --sbom=true --push $images "${params[@]}"
  fi
  docker buildx build . --load $images "${params[@]}"
) 2>&1 | tee build-$IMAGE_TAG.log

if [ -n "$TEST_WEB" ]; then
  log="test-$IMAGE_TAG.log"
  (docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v /root/.cache/trivy:/root/.cache/trivy aquasec/trivy image $default_image 2>&1) | tee $log
  grep -q 'Total:' $log && exit 1

  "$BIN_DIR/test.sh" $default_image | tee -a $log
  if [[ $IMAGE_TAG != cs ]]; then
    grep -q 'https ok' $log || exit 1
  fi
fi

echo -e "\033[36;1m>>> $(echo "$images" | sed 's/-t //g')\033[0m"
