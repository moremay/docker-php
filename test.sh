#!/bin/bash

set -e

image="$1"
if [ -z "$image" ]; then
  echo "Usage: ./test.sh <image>"
  exit
fi

if ! docker image inspect -f "{{.Config.Entrypoint}}{{.Config.Cmd}}" $image | grep -q 'php-fpm'; then
  echo "Not php-fpm !"
  exit
fi

if ! command -v cgi-fcgi > /dev/null; then
  sudo apt-get install libfcgi0ldbl
fi

docker run -d -it --rm -v "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/index.php":/var/www/html/index.php -p 9000:9000 --name test-php-fpm $image
trap 'docker stop test-php-fpm >/dev/null' EXIT

sleep 2
SCRIPT_NAME=/index.php SCRIPT_FILENAME=/var/www/html/index.php REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || echo "Failed $?"
