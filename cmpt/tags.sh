#!/bin/bash

set -e

cmptver=($(docker run --rm temp /bin/sh -c "cd /cmpt; composer show phpcompatibility/php-compatibility 2>/dev/null" | grep '^versions' | sed 's/\r//'))
cmptver=${cmptver[-1]}
echo "cmpt-$cmptver phpcompatibility:latest phpcompatibility:$cmptver"
