# syntax=docker/dockerfile:1.4
ARG mirrors=
ARG gnu_mirrors=http://ftp.gnu.org/pub/gnu
ARG TZ=

FROM alpine:3.23 AS builder

ARG mirrors
ARG gnu_mirrors
ARG TZ

COPY script/docker-* /usr/local/bin/
COPY apk/x86_64 /usr/src/repo/x86_64

RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories; \
	if [ -n "${mirrors}" ]; then \
		sed "s/dl-cdn.alpinelinux.org/${mirrors}/g" -i /etc/apk/repositories; \
	fi; \
	echo '/usr/src/repo/' >> /etc/apk/repositories

ENV VER_WOLFSSL=5.9.1-r100
ENV VER_CURL=8.19.0-r100

RUN apk add --allow-untrusted --no-cache \
	# edge
	busybox~1.37.0-r31 \
	openssl~3.5.6-r0 \
	nghttp2~1.68.1-r0 \
	# local
	wolfssl=${VER_WOLFSSL} \
	curl=${VER_CURL}

ENV PHPIZE_DEPS="autoconf file g++ gcc libc-dev make pkgconf re2c patch dpkg-dev dpkg"
ENV PHP_CFLAGS="-std=gnu11 -fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -Wno-discarded-qualifiers -Wno-incompatible-pointer-types -Wno-compare-distinct-pointer-types -Wno-implicit-int -Wno-implicit-function-declaration"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV PHP_SSL=/usr/local/ssl1.1

RUN set -eux; \
	TARGET="${PHP_SSL}"; \
	. docker-lib init 'openssl-1.1' \
		"https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz" \
		'cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8' \
		linux-headers; \
	./config shared --prefix=${TARGET} --openssldir=${TARGET}/ssl; \
	docker-lib make; \
	rm -rf ${TARGET}/ssl/man

# php7: /usr/local
RUN set -eux; \
	. docker-lib init "libiconv" \
		"${gnu_mirrors}/libiconv/libiconv-1.19.tar.gz" \
		"88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6"; \
	./configure --prefix=$TARGET; \
	docker-lib make

RUN set -ex; \
	docker-lib download /usr/src/php \
		"https://www.php.net/distributions/php-7.4.33.tar.xz" \
		"924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927"

ENV TZ=${TZ:-Asia/Shanghai}
ENV PHP_VERSION=7.4.33
ENV PHP_INI_DIR=/usr/local/etc/php

RUN set -eux; \
	. docker-lib php-init \
		argon2-dev \
		coreutils \
		libsodium-dev \
		libxml2-dev \
		linux-headers \
		oniguruma-dev \
		readline-dev \
		sqlite-dev \
		zlib-dev \
		; \
	\
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	export \
		PKG_CONFIG_PATH="/usr/local/ssl1.1/lib/pkgconfig" \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS -Wl,--enable-new-dtags,-R,${PHP_SSL}/lib:/usr/local/lib" \
	; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--build="$gnuArch" \
		--enable-option-checking=fatal \
		--disable-cgi \
		--disable-phpdbg \
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
		\
		--enable-mbregex \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-mhash \
		--with-pic \
		--with-password-argon2 \
		--with-sodium=shared \
		\
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		\
		--with-iconv=/usr/local \
		--with-libxml \
		--with-openssl=${PHP_SSL} \
		--with-pear \
		--with-readline \
		--with-zlib \
	; \
	docker-lib make; \
	\
	docker-php-ext-enable \
		sodium \
		opcache \
	; \
	\
	php -v

RUN set -eux; \
	mkdir -p "$(php -r "echo ini_get('extension_dir');")"; \
	cd /usr/local/etc; \
	# /usr/local/etc
	sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
	cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	# /usr/local/etc/php-fpm.d
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; \
		echo 'log_limit = 8192'; \
		echo; \
		echo '[www]'; \
		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/1 does not work.'; \
		echo '; https://bugs.php.net/bug.php?id=73886'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
		echo 'decorate_workers_output = no'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/zz-docker.conf; \
	# /usr/local/etc/php/conf.d
	cd "$PHP_INI_DIR/conf.d"; \
	{ \
		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
		echo 'fastcgi.logging = Off'; \
	} > "docker-fpm.ini"; \
	{ \
		echo '[Date]'; \
		echo 'date.timezone = ${TZ}'; \
	} > "timezone.ini"; \
	echo "expose_php = Off" > disable-x-powered-by.ini

RUN set -eux; \
	. docker-lib php-init \
		bzip2-dev \
		curl-dev=${VER_CURL} \
		freetype-dev \
		gettext-dev \
		gmp-dev \
		icu-dev \
		libjpeg-turbo-dev \
		libmcrypt-dev \
		libpng-dev \
		libwebp-dev \
		libxpm-dev \
		libxslt-dev \
		libzip-dev \
		unixodbc-dev \
		postgresql18-dev \
		#brotli-dev c-ares-dev libidn2-dev libpsl-dev nghttp2-dev  zstd-dev \
		zlib-dev \
	; \
	docker-lib download "ext/redis" \
		"https://github.com/phpredis/phpredis/archive/refs/tags/6.2.0.tar.gz" \
		"470333b27cbf9485d36b610b81300c06491a6575f22c6801a9cefc55285ed123" \
		tar; \
	docker-lib download "ext/timezonedb" \
		"https://pecl.php.net/get/timezonedb-2025.2.tgz" \
		"ae32b224a843df303d61bffbf38ce325e0ca6117b92a974a101a6729d1ce5fea" \
		tar; \
	\
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg \
		--with-webp \
		--with-xpm \
	; \
	docker-php-ext-configure pdo_odbc \
		--with-pdo-odbc=unixODBC,/usr; \
	\
	docker-php-ext-install \
		bcmath \
		bz2 \
		curl \
		exif \
		gd \
		gettext \
		gmp \
		mysqli \
		pdo_mysql \
		pdo_odbc \
		pdo_pgsql \
		pgsql \
		redis \
		sockets \
		timezonedb \
		xsl \
		zip \
	; \
	\
	docker-lib prune

RUN set -eux; \
	FILE_PATH="/usr/local/bin/composer";\
	FILE_SHA256="$(curl -Lk https://getcomposer.org/download/latest-stable/composer.phar.sha256)"; \
	curl -Lko "$FILE_PATH" https://getcomposer.org/download/latest-stable/composer.phar; \
	echo "$FILE_SHA256 *$FILE_PATH" | sha256sum -c -; \
	chmod +x "$FILE_PATH"; \
	\
	composer --version

RUN find /usr/local/include/* -type d ! -path "*/php" -maxdepth 0 -exec rm -rf {} \;
RUN rm -rf /usr/src/repo /usr/share/man/* /usr/share/doc/*

FROM scratch
LABEL org.opencontainers.image.authors="moremay"
LABEL org.opencontainers.image.source="https://github.com/moremay/docker-php"
LABEL org.opencontainers.image.licenses="MIT"

ARG TZ

ENV TZ=${TZ:-Asia/Shanghai}
ENV PHP_VERSION=7.4.33
ENV PHP_INI_DIR=/usr/local/etc/php

ENV PHPIZE_DEPS="autoconf file g++ gcc libc-dev make pkgconf re2c patch dpkg-dev dpkg"
ENV PHP_CFLAGS="-std=gnu11 -fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -Wno-discarded-qualifiers -Wno-incompatible-pointer-types -Wno-compare-distinct-pointer-types -Wno-implicit-int -Wno-implicit-function-declaration"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

COPY --from=builder / /

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
