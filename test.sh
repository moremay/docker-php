#!/bin/bash

set -e

ver=
if [[ -n "$1" && "${1:0,1}" != "-" ]]; then
  ver="$1"
  shift
elif [ -f "Dockerfile" ]; then
  ver="$(basename $(pwd))"
fi

if [ -z "$ver" ]; then
  ver="8.4"
fi

if ! command -v cgi-fcgi > /dev/null; then
  sudo apt-get install libfcgi0ldbl
fi

docker run -d -it --rm -v "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/index.php":/var/www/html/index.php -p 9000:9000 --name test-php-fpm moremay/php:$ver
trap 'docker stop test-php-fpm >/dev/null' EXIT

sleep 2
SCRIPT_NAME=/index.php SCRIPT_FILENAME=/var/www/html/index.php REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || echo "Failed $?"
