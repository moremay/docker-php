#!/bin/bash

set -e

dirs=($(ls -d */))

for ver in "${dirs[@]}"; do
  [ -f "$ver/Dockerfile" ] || continue
  echo "Build ${ver///}"
  ./build.sh ${ver///}
done
