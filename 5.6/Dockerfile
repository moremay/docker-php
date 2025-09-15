# syntax=docker/dockerfile:1.4
ARG mirrors=
ARG gnu_mirrors=http://ftp.gnu.org/pub/gnu
ARG TZ=

FROM alpine:3.18 AS builder

ARG mirrors
ARG gnu_mirrors
ARG TZ

COPY docker-* /usr/local/bin/

RUN if [ -n "${mirrors}" ]; then \
		sed "s/dl-cdn.alpinelinux.org/${mirrors}/g" -i /etc/apk/repositories; \
	fi

RUN apk add --no-cache \
		ca-certificates \
		curl \
		tar \
		xz \
	; \
	update-ca-certificates

ENV PHPIZE_DEPS="autoconf gcc libc-dev make"

RUN set -ex; \
	. docker-lib init 'openssl-1.0' \
		"https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_2u/openssl-1.0.2u.tar.gz" \
		'ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16'; pwd;\
	./config shared --prefix=/usr/local; \
	. docker-lib make; \
	rm -rf /usr/local/ssl/man

RUN set -ex; \
	. docker-lib init "libiconv" \
		"${gnu_mirrors}/libiconv/libiconv-1.18.tar.gz" \
		"3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8"; \
	./configure --prefix=/usr/local; \
	. docker-lib make; \
	ln -s /usr/local/lib/libiconv.so* /lib/

RUN set -eux; \
	. docker-lib init "zlib-1.2" \
		"https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz" \
		"b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30"; \
	./configure --prefix=/usr/local; \
	. docker-lib make

RUN set -ex; \
	. docker-lib init "libxml2-2.12" \
		"https://download.gnome.org/sources/libxml2/2.12/libxml2-2.12.10.tar.xz" \
		"c3d8c0c34aa39098f66576fe51969db12a5100b956233dc56506f7a8679be995"; \
	./configure --prefix=/usr/local \
		--with-python=no \
		--with-http=no \
		--with-readline=no \
		--with-lzma=no \
		--with-zlib=no \
		; \
	. docker-lib make

RUN set -ex; \
	. docker-lib init "freetype" \
		"https://download.savannah.gnu.org/releases/freetype/freetype-2.14.1.tar.xz" \
		"32427e8c471ac095853212a37aef816c60b42052d4d9e48230bab3bdf2936ccc"; \
	./configure --prefix=/usr/local --enable-freetype-config; \
	. docker-lib make

RUN set -ex; \
	. docker-lib download php \
		"https://www.php.net/distributions/php-5.6.40.tar.xz" \
		"1369a51eee3995d7fbd1c5342e5cc917760e276d561595b6052b21ace2656d1c"

ENV TZ=${TZ:-Asia/Shanghai}
ENV PHP_VERSION=5.6.40
ENV PHP_INI_DIR=/usr/local/etc/php

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

RUN set -eux; \
	. docker-lib php-init \
		curl-dev \
		readline-dev \
		sqlite-dev \
	; \
	\
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	; \
	./configure \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--enable-option-checking=fatal \
		--disable-cgi \
		--disable-phpdbg \
		--enable-fpm \
		#--enable-maintainer-zts \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
		\
		--enable-ftp \
		--enable-mbregex \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-curl \
		--with-iconv=/usr/local \
		--with-libxml-dir=/usr/local \
		--with-mhash \
		--with-onig \
		--with-openssl=/usr/local \
		--with-pear \
		--with-pic \
		--with-readline \
		--with-zlib=/usr/local \
		\
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
	; \
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	. docker-lib make; \
	php -v

RUN set -eux; \
	mkdir -p /usr/local/etc/php-fpm.d "$(php -r "echo ini_get('extension_dir');")"; \
	cd /usr/local/etc; \
	cp php-fpm.conf.default php-fpm.d/www.conf; \
	{ \
		echo '[global]'; \
		echo 'include=etc/php-fpm.d/*.conf'; \
	} | tee php-fpm.conf; \
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; \
		echo '[www]'; \
		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/1 does not work.'; \
		echo '; https://bugs.php.net/bug.php?id=73886'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/zz-docker.conf; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	{ \
		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
		echo 'fastcgi.logging = Off'; \
	} > "$PHP_INI_DIR/conf.d/docker-fpm.ini"; \
	\
	cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN set -eux; \
	. docker-lib php-init \
		bzip2-dev \
		gettext-dev \
		gmp-dev \
		icu-dev \
		libjpeg-turbo-dev \
		libmcrypt-dev \
		libpng-dev \
		libvpx-dev \
		libxpm-dev \
		libxslt-dev \
	; \
	\
	docker-php-ext-configure \
		gd \
		--enable-gd-native-ttf \
		--with-freetype-dir=/usr/local \
		--with-jpeg-dir \
		--with-png-dir \
		--with-vpx-dir \
		--with-xpm-dir \
	; \
	\
	docker-php-ext-install \
		bcmath \
		bz2 \
		exif \
		gd \
		gettext \
		gmp \
		mcrypt \
		mysql \
		mysqli \
		opcache \
		pdo_mysql \
		sockets \
		xsl \
		zip \
	; \
	\
	. docker-lib prune

RUN set -eux; \
	. docker-lib php-init; \
	\
	curl -kLo /usr/local/ssl/cert.pem https://curl.se/ca/cacert.pem; \
	pecl update-channels; \
	\
	pecl install \
		redis-4.3.0 \
		timezonedb \
	; \
	chmod +x "$(php -r "echo ini_get('extension_dir');")"/*.so; \
	\
	docker-php-ext-enable \
		redis \
		timezonedb \
	; \
	\
	rm -rf ~/.pearrc; \
	. docker-lib prune

RUN set -eux; \
	FILE_PATH="/usr/local/bin/composer";\
	FILE_SHA256='8b3f41253363f0645402d1951d6e7f02adedeef29c16de6074763e463e25c23f'; \
	curl -Lko "$FILE_PATH" https://getcomposer.org/download/2.2.25/composer.phar; \
	echo "$FILE_SHA256 *$FILE_PATH" | sha256sum -c -; \
	chmod u+x "$FILE_PATH"; \
	\
	composer --version

RUN set -eux; \
	adduser -u 82 -D -S -G www-data www-data; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

WORKDIR /var/www/html
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm"]
EXPOSE 9000

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT
