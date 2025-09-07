#!/bin/bash

set -e

cmptver=($(docker run --rm temp /bin/sh -c "cd /cmpt; composer show phpcompatibility/php-compatibility 2>/dev/null" | grep '^versions' | sed 's/\r//'))
cmptver=${cmptver[-1]}
echo "php-compatibility:latest php-compatibility:$cmptver"
