# syntax=docker/dockerfile:1.4
ARG mirrors=
ARG TZ=

FROM alpine:3.23 AS builder

ARG mirrors
ARG TZ

COPY script/docker-* /usr/local/bin/
COPY apk/x86_64 /usr/src/repo/x86_64

RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories; \
	if [ -n "${mirrors}" ]; then \
		sed "s/dl-cdn.alpinelinux.org/${mirrors}/g" -i /etc/apk/repositories; \
	fi; \
	echo '/usr/src/repo/' >> /etc/apk/repositories

RUN apk add --allow-untrusted --no-cache \
	curl~8.20.0-r0 \
	musl~1.2.6-r2 \
	musl-utils~1.2.6-r2 \
	busybox~1.37.0-r31

ENV PHPIZE_DEPS="musl-dev~1.2.6-r2 autoconf file g++ gcc libc-dev make pkgconf re2c patch dpkg-dev dpkg"
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

# php5, 7: /usr/local
# php8等待alpine更新
RUN set -eux; \
	. docker-lib init "libiconv" \
		"http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.19.tar.gz" \
		"88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6"; \
	./configure --prefix=$TARGET; \
	docker-lib make

RUN set -ex; \
	docker-lib download /usr/src/php \
		"https://www.php.net/distributions/php-8.5.5.tar.xz" \
		"95bec382f4bd00570a8ef52a58ec04d8d9b9a90494781f1c106d1b274a3902f2"

ENV TZ=${TZ:-Asia/Shanghai}
ENV PHP_VERSION=8.5.5
ENV PHP_INI_DIR=/usr/local/etc/php

RUN set -eux; \
	. docker-lib php-init \
		argon2-dev \
		coreutils \
		libsodium-dev \
		libxml2-dev \
		linux-headers \
		oniguruma-dev \
		openssl-dev \
		readline-dev \
		sqlite-dev \
		zlib-dev \
	; \
	rm -vf /usr/include/iconv.h; \
	\
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
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
		--with-iconv=/usr/local \
		--with-libxml \
		--with-mhash \
		--with-openssl \
		--with-password-argon2 \
		--with-pdo-sqlite=/usr \
		--with-pear \
		--with-pic \
		--with-readline \
		--with-sodium=shared \
		--with-sqlite3=/usr \
		--with-zlib \
	; \
	docker-lib make; \
	\
	docker-php-ext-enable \
		sodium \
	; \
	\
	php -v

RUN set -eux; \
	mkdir -p /usr/local/etc/php-fpm.d "$(php -r "echo ini_get('extension_dir');")"; \
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
	} > docker-fpm.ini; \
	{ \
		echo '[Date]'; \
		echo 'date.timezone = ${TZ}'; \
	} > timezone.ini; \
	echo "expose_php = Off" > disable-x-powered-by.ini

RUN set -eux; \
	. docker-lib php-init \
		bzip2-dev \
		curl-dev \
		freetype-dev \
		gettext-dev \
		gmp-dev \
		icu-dev \
		libavif-dev \
		libjpeg-turbo-dev \
		libmcrypt-dev \
		libpng-dev \
		libwebp-dev \
		libxpm-dev \
		libxslt-dev \
		libzip-dev \
		linux-headers \
		postgresql18-dev \
		unixodbc-dev \
	; \
	\
	docker-lib download "ext/redis" \
		"https://github.com/phpredis/phpredis/archive/refs/tags/6.3.0.tar.gz" \
		"cb8f81df1a275599e4f8ddcfec7e1f65ed1953e6f5673649149fd680ebff4cad" \
		tar; \
	docker-lib download "ext/timezonedb" \
		"https://pecl.php.net/get/timezonedb-2026.1.tgz" \
		"ca53eeed51c21ff8ade4ed52cc4095a13eec4037682a3c3fb3947f61108f5091" \
		tar; \
	\
	docker-php-ext-configure gd \
		--with-avif \
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
ENV PHP_VERSION=8.5.5
ENV PHP_INI_DIR=/usr/local/etc/php

ENV PHPIZE_DEPS="musl-dev~1.2.6-r2 autoconf file g++ gcc libc-dev make pkgconf re2c patch dpkg-dev dpkg"
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
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
