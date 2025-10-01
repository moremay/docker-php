#!/bin/bash

set -e

img=
showall=
while [ $# -gt 0 ]; do
  case "$1" in
  -a | --show-all)
    showall=yes
    ;;
  *)
    img="$1"
    ;;
  esac
  shift
done

if [[ -z "$img" ]]; then
  echo "Miss image name"
  exit 1
fi

layers=()

mapfile -t cmds < <(docker history --no-trunc --format '{{.CreatedBy}}' "$img" | grep -i "^ADD\|^COPY\|^RUN\|^WORKDIR")
cmds_last=$((${#cmds[@]} - 1))

set_layers() {
  local info=($(docker inspect "$img" | grep "$1"))
  info="${info[1]##\"}"
  info=($(echo "${info%%\"*}" | tr ':' '\n'))
  layers=("${layers[@]}" "${info[@]}")
}

file_list() {
  find "$1" -type f,l | sed "s|^$1||" | sort
}

set_layers "UpperDir"
set_layers "LowerDir"

layer_last=$(("${#layers[@]}" - 1))
all_files=$(file_list "${layers[$layer_last]}")

echo -e "\033[36;1mCount: ${#layers[@]}\033[0m"
echo -e "\033[36;1mLayer 0:\033[0m"
echo "${cmds[$cmds_last]}"
echo "    -"

for ((i=1; i <= layer_last; i++)); do
  echo -e "\033[36;1mLayer $i:\033[0m"
  echo "${cmds[$((cmds_last-i))]}"

  files=$(file_list "${layers[$((layer_last-i))]}")
  exists=$(comm -12 <(echo "$all_files") <(echo "$files"))
  if [ -n "$exists" ]; then
    if [ "$showall" != "yes" ]; then
      info="${exists:0:200}"
      test "$info" = "$exists" || info="$info..."
    else
      info="${exists}"
    fi
    echo "$info" | sed 's/^/    /g'
  else
    echo "    -"
  fi

  all_files=$(
    {
      echo "$all_files"
      echo "$files"
    } | sort -u
  )
done

echo "END"
