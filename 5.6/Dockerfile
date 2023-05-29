# syntax=docker/dockerfile:1

FROM php:5.6.40-fpm-alpine

COPY docker-apk-* /usr/local/bin/

RUN set -eux; \
	apk add --no-cache --virtual .phpize-deps \
		$PHPIZE_DEPS \
		bzip2-dev \
		freetype-dev \
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
	update-ca-certificates; \
	\
	docker-php-source extract; \
	\
	docker-php-ext-configure \
		gd \
		--enable-gd-native-ttf \
		--with-freetype-dir \
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
	docker-apk-prune; \
	\
	cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
	sed -i 's#^;date\.timezone.*$#date.timezone = "Asia/Shanghai"#' "$PHP_INI_DIR/php.ini"

RUN set -eux; \
	apk add --no-cache --virtual .phpize-deps \
		$PHPIZE_DEPS \
	; \
	\
	docker-php-source extract; \
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
	rm -rf /tmp/pear ~/.pearrc; \
	docker-apk-prune

RUN set -eux; \
	wget -O /usr/bin/composer https://getcomposer.org/download/latest-2.2.x/composer.phar; \
	chmod u+x /usr/bin/composer; \
	composer --version
