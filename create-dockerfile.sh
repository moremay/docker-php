#!/bin/bash

set -e

work="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
echo "Enter $work"
pushd "$work" >/dev/null
trap "echo Leave $work; popd >/dev/null" EXIT

create_file() {
  local ver="$1"
  echo "Create $ver ..."
  awk -f template.awk Dockerfile.template > "$ver/Dockerfile"
}

PHPIZE_DEPS_5="musl-dev~1.2.6-r2 autoconf file g++ gcc libc-dev make pkgconf re2c patch"
PHPIZE_DEPS_7_8="musl-dev~1.2.6-r2 autoconf file g++ gcc libc-dev make pkgconf re2c patch dpkg-dev dpkg"

PHP_CFLAGS_5_7="-std=gnu11 -fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -Wno-discarded-qualifiers -Wno-incompatible-pointer-types -Wno-compare-distinct-pointer-types -Wno-implicit-int -Wno-implicit-function-declaration"
PHP_CFLAGS_8="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"

export TMPL_php_ver=8.5.5
export TMPL_php_url="https://www.php.net/distributions/php-8.5.5.tar.xz"
export TMPL_php_sha256="95bec382f4bd00570a8ef52a58ec04d8d9b9a90494781f1c106d1b274a3902f2"
export TMPL_PHPIZE_DEPS="$PHPIZE_DEPS_7_8"
export TMPL_PHP_CFLAGS="$PHP_CFLAGS_8"
export TMPL_ver=${TMPL_php_ver%.*}
create_file $TMPL_ver

export TMPL_php_ver=8.4.20
export TMPL_php_url="https://www.php.net/distributions/php-8.4.20.tar.xz"
export TMPL_php_sha256="e454c6f7c89a42f41ebb06dc5c3578e8c8b5f1a3f0da6675665affab04e221f7"
export TMPL_PHPIZE_DEPS="$PHPIZE_DEPS_7_8"
export TMPL_PHP_CFLAGS="$PHP_CFLAGS_8"
export TMPL_ver=${TMPL_php_ver%.*}
create_file $TMPL_ver

export TMPL_php_ver=7.4.33
export TMPL_php_url="https://www.php.net/distributions/php-7.4.33.tar.xz"
export TMPL_php_sha256="924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927"
export TMPL_PHPIZE_DEPS="$PHPIZE_DEPS_7_8"
export TMPL_PHP_CFLAGS="$PHP_CFLAGS_5_7"
export TMPL_ver=${TMPL_php_ver%.*}
create_file $TMPL_ver

export TMPL_php_ver=5.6.40
export TMPL_php_url="https://www.php.net/distributions/php-5.6.40.tar.xz"
export TMPL_php_sha256="1369a51eee3995d7fbd1c5342e5cc917760e276d561595b6052b21ace2656d1c"
export TMPL_PHPIZE_DEPS="$PHPIZE_DEPS_5"
export TMPL_PHP_CFLAGS="$PHP_CFLAGS_5_7"
export TMPL_ver=${TMPL_php_ver%.*}
create_file $TMPL_ver

export TMPL_php_ver=5.4.45
export TMPL_php_url="https://www.php.net/distributions/php-5.4.45.tar.gz"
export TMPL_php_sha256="25bc4723955f4e352935258002af14a14a9810b491a19400d76fcdfa9d04b28f"
export TMPL_PHPIZE_DEPS="$PHPIZE_DEPS_5"
export TMPL_PHP_CFLAGS="$PHP_CFLAGS_5_7"
export TMPL_ver=${TMPL_php_ver%.*}
create_file $TMPL_ver
