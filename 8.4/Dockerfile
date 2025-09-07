ARG composer=
ARG mirrors=

FROM php:8.4-fpm-alpine

ARG composer
ARG mirrors

COPY docker-apk-* /usr/local/bin/

RUN \
	{ \
		echo "[date]"; \
		echo 'date.timezone = "Asia/Shanghai"'; \
	} | tee php-fpm.d/timezone.conf; \
	cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
	sed -i 's#^;date\.timezone.*$#date.timezone = "Asia/Shanghai"#' "$PHP_INI_DIR/php.ini"

RUN if [ -n "${mirrors}" ]; then \
		sed "s/dl-cdn.alpinelinux.org/${mirrors}/g" -i /etc/apk/repositories; \
	fi

RUN set -eux; \
	apk add --no-cache --virtual .phpize-deps \
		$PHPIZE_DEPS \
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
		unixodbc-dev \
	; \
	\
	docker-php-source extract; \
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
	docker-php-ext-configure \
		pdo_odbc --with-pdo-odbc=unixODBC,/usr \
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
		opcache \
		pdo_mysql \
		pdo_odbc \
		sockets \
		xsl \
		zip \
	; \
	\
	docker-apk-prune;
RUN set -eux; \
	apk add --no-cache --virtual .phpize-deps \
		$PHPIZE_DEPS \
	; \
	\
	docker-php-source extract; \
	pecl update-channels; \
	\
	pecl install \
		redis \
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
	if [ "${composer}" == "yes" ]; then \
	FILE_SHA256="$(curl https://getcomposer.org/download/latest-stable/composer.phar.sha256)"; \
	curl -o /usr/bin/composer https://getcomposer.org/download/latest-stable/composer.phar; \
	echo "$FILE_SHA256 */usr/bin/composer" | sha256sum -c -; \
	chmod u+x /usr/bin/composer; \
	\
	composer --version; \
	fi
