#!/bin/bash

set -e

phpdir=.
phpfile=
params=()
volumes=()

usage() {
    echo "Usage: "
    echo "$0"' [-v|--volume list] [-p .]|<-p path/to/php-dir-or-file> [PHP CodeSniffer options]'
    echo "$0 --usage"
    cat <<EOF

docker options:
    -v|--volume list    Bind mount a volume
    -p|--path path      php dir / file

phpcs options:
    -h|--help           => phpcs --help

--usage                 Print this message

EOF
}

while [ $# -gt 0 ]; do
    case $1 in
    -v|--volume)
        shift
        [ -n "$1" ] && volumes=("${volumes[@]}" -v "$1")
        ;;
    -p|--path)
        shift
        if [ -z "$1" ]; then
            usage
            exit 1
        fi
        if [ -d "$1" ]; then
            phpdir="$1"
            phpfile=""
        elif [ -f "$1" ]; then
            phpdir="$(dirname "$1")"
            phpfile="/$(basename "$1")"
        else
            echo "Target not found '$1'"
            exit 1
        fi
        ;;
    --usage)
        usage
        exit 1
        ;;
    *)
        params=("${params[@]}" "$1")
        ;;
    esac
    shift
done

bindir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

if [ -f "$phpdir/phpcs.xml" ]; then
    echo "OUTPUT $phpdir/PHPCS-report.txt"
	params=("${params[@]}" --standard=/www/phpcs.xml)
else
    echo "OUTPUT $bindir/PHPCS-report.txt"
	params=("${params[@]}" --standard=/phpcs/phpcs.xml)
fi

set -x
docker run --rm -it -v "$phpdir":/www/ -v "$bindir":/phpcs/ "${volumes[@]}" moremay/php:8 /phpcs/vendor/bin/phpcs "/www$phpfile" "${params[@]}"
