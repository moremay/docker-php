# syntax=docker/dockerfile:1.4
ARG mirrors=
ARG gnu_mirrors=http://ftp.gnu.org/pub/gnu
ARG TZ=

FROM php:8.4-fpm-alpine

ARG mirrors
ARG gnu_mirrors
ARG TZ

COPY docker-* /usr/local/bin/

RUN if [ -n "${mirrors}" ]; then \
		sed "s/dl-cdn.alpinelinux.org/${mirrors}/g" -i /etc/apk/repositories; \
	fi

ENV TZ=${TZ:-Asia/Shanghai}

RUN set -eux; \
	# /usr/local/etc/php
	cd "$PHP_INI_DIR"; \
	{ \
		echo '[Date]'; \
		echo 'date.timezone = ${TZ}'; \
	} > "conf.d/timezone.ini"

RUN set -eux; \
	. docker-lib php-init \
		bzip2-dev \
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
		postgresql17-dev \
		unixodbc-dev \
	; \
	\
	docker-lib download "php/ext/redis" \
		"https://github.com/phpredis/phpredis/archive/refs/tags/6.2.0.tar.gz" \
		"470333b27cbf9485d36b610b81300c06491a6575f22c6801a9cefc55285ed123" \
		tar; \
	docker-lib download "php/ext/timezonedb" \
		"https://pecl.php.net/get/timezonedb-2025.2.tgz" \
		"ae32b224a843df303d61bffbf38ce325e0ca6117b92a974a101a6729d1ce5fea" \
		tar; \
	\
	docker-php-ext-configure \
		gd \
		--with-avif \
		--with-freetype \
		--with-jpeg \
		--with-webp \
		--with-xpm \
	; \
	\
	docker-php-ext-configure pdo_odbc \
		--with-pdo-odbc=unixODBC,/usr \
	; \
	\
	docker-php-ext-install \
		bcmath \
		bz2 \
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
