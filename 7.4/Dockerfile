# syntax=docker/dockerfile:1

FROM alpine:3.16

COPY docker-* /usr/local/bin/

ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c

RUN apk add --no-cache \
		ca-certificates \
		curl \
		tar \
		xz \
	; \
	update-ca-certificates

RUN set -eux; \
	adduser -u 82 -D -S -G www-data www-data

RUN set -eux; \
	\
	OPENSSL_NAME='openssl-1.1.1u'; \
	OPENSSL_URL="https://www.openssl.org/source/$OPENSSL_NAME.tar.gz"; \
	OPENSSL_SHA256='e2f8d84b523eecd06c7be7626830370300fbcc15386bf5142d72758f6963ebc6'; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	curl -kO "$OPENSSL_URL"; \
	echo "$OPENSSL_SHA256 *$OPENSSL_NAME.tar.gz" | sha256sum -c -; \
	tar xzf "$OPENSSL_NAME.tar.gz"; \
	\
	apk add --no-cache --virtual .phpize-deps \
		$PHPIZE_DEPS \
	; \
	\
	cd "$OPENSSL_NAME"; \
	./config shared --prefix=/usr/local; \
	make -j $(nproc) && make install; \
	make clean; \
	\
	cd /usr/src; \
	rm -rf /usr/src/openssl*; \
	\
	docker-apk-prune /usr/local

RUN set -eux; \
	\
	GNUICONV_NAME="libiconv-1.17"; \
	GNUICONV_URL="http://ftp.gnu.org/pub/gnu/libiconv/$GNUICONV_NAME.tar.gz"; \
	GNUICONV_SHA256="8f74213b56238c85a50a5329f77e06198771e70dd9a739779f4c02f65d971313"; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	curl -kO "$GNUICONV_URL"; \
	echo "$GNUICONV_SHA256 *$GNUICONV_NAME.tar.gz" | sha256sum -c -; \
	tar xzf "$GNUICONV_NAME.tar.gz"; \
	\
	apk add --no-cache --virtual .phpize-deps \
		$PHPIZE_DEPS \
	; \
	\
	cd "$GNUICONV_NAME"; \
	./configure --prefix=/usr/local; \
	make -j $(nproc) && make install; \
	make clean; \
	ln -s /usr/local/lib/libiconv.so* /lib/; \
	\
	cd /usr/src; \
	rm -rf /usr/src/libiconv*; \
	rm -vf /usr/include/iconv.h; \
	\
	docker-apk-prune /usr/local

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV PHP_VERSION 7.4.33
ENV PHP_URL="https://www.php.net/distributions/php-7.4.33.tar.xz"
ENV PHP_SHA256="924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927"

RUN set -eux; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	curl -ko php.tar.xz "$PHP_URL"; \
	\
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi

RUN set -eux; \
	apk add --no-cache --virtual .phpize-deps \
		$PHPIZE_DEPS \
		argon2-dev \
		coreutils \
		curl-dev \
		libsodium-dev \
		libxml2-dev \
		linux-headers \
		oniguruma-dev \
		readline-dev \
		sqlite-dev \
	; \
	\
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
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
		--enable-ftp \
		--enable-mbregex \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-curl \
		--with-iconv=/usr/local \
		--with-libxml \
		--with-mhash \
		--with-openssl=/usr/local \
		--with-password-argon2 \
		--with-pear \
		--with-pic \
		--with-readline \
		--with-sodium=shared \
		--with-zlib \
		\
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
	; \
	make -j $(nproc); \
	find -type f -name '*.a' -delete; \
	make install; \
	\
	docker-php-ext-enable \
		sodium \
	; \
	\
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	docker-apk-prune /usr/local; \
	\
	php -v

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

RUN set -eux; \
	mkdir -p "$(php -r "echo ini_get('extension_dir');")"; \
	cd /usr/local/etc; \
	if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi; \
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
	cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
	sed -i 's#^;date\.timezone.*$#date.timezone = "UTC"#' "$PHP_INI_DIR/php.ini"

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm"]

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
		libwebp-dev \
		libxpm-dev \
		libxslt-dev \
		libzip-dev \
	; \
	\
	docker-php-source extract; \
	\
	docker-php-ext-configure \
		gd \
		--with-freetype \
		--with-jpeg \
		--with-webp \
		--with-xpm \
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
		sockets \
		xsl \
		zip \
	; \
	\
	docker-apk-prune

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
	\
	FILE_SHA256="$(curl https://getcomposer.org/download/latest-stable/composer.phar.sha256)"; \
	curl -o /usr/bin/composer https://getcomposer.org/download/latest-stable/composer.phar; \
	echo "$FILE_SHA256 */usr/bin/composer" | sha256sum -c -; \
	chmod u+x /usr/bin/composer; \
	\
	composer --version
