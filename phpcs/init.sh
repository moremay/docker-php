#!/bin/sh

set -e

if [ $# -eq 0 ]; then
    docker run --rm -it -v .:/phpcs/ moremay/php:8 /bin/sh -c "/phpcs/init.sh init"
else
    cd /phpcs

    if [ -f composer.json ]; then
        composer update phpcompatibility/php-compatibility --with-dependencies
    else
        echo "{}" >composer.json
        composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
        composer require --dev phpcompatibility/php-compatibility:"^10.0.0@dev"
    fi
fi
