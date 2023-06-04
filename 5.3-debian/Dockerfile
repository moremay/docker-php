# syntax=docker/dockerfile:1

FROM debian:stretch-slim

COPY sources.list.9 /etc/apt/sources.list

# docker-php-* from docker-library/php
COPY docker-* /usr/local/bin/

ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkg-config \
		re2c

RUN set -eux; \
	{ \
		echo 'Package: php*'; \
		echo 'Pin: release *'; \
		echo 'Pin-Priority: -1'; \
	} > /etc/apt/preferences.d/no-debian-php; \
	\
	rm -f /etc/apt/apt.conf.d/docker-clean; \
	echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=id=stretch,type=cache,target=/var/cache/apt,sharing=shared \
	--mount=id=stretch,type=cache,target=/var/lib/apt,sharing=shared \
	set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		xz-utils \
	; \
	update-ca-certificates; \
	\
	docker-apt-mark

RUN --mount=id=stretch,type=cache,target=/var/cache/apt,sharing=shared \
	--mount=id=stretch,type=cache,target=/var/lib/apt,sharing=shared \
	set -eux; \
	\
	OPENSSL_NAME='openssl-1.0.2u'; \
	OPENSSL_URL="https://www.openssl.org/source/old/1.0.2/$OPENSSL_NAME.tar.gz"; \
	OPENSSL_SHA256='ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16'; \
	\
	cd /usr/src; \
	curl -O "$OPENSSL_URL"; \
	echo "$OPENSSL_SHA256 *$OPENSSL_NAME.tar.gz" | sha256sum -c -; \
	tar xzf "$OPENSSL_NAME.tar.gz"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
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
	cd /usr/include; \
	ln -s x86_64-linux-gnu/curl; \
	\
	docker-apt-prune /usr/local

RUN --mount=id=stretch,type=cache,target=/var/cache/apt,sharing=shared \
	--mount=id=stretch,type=cache,target=/var/lib/apt,sharing=shared \
	set -eux; \
	\
	BISON_NAME='bison-2.6.4'; \
	BISON_URL="http://ftp.gnu.org/gnu/bison/$BISON_NAME.tar.xz"; \
	BISON_SHA256='e0c3179ed1a622d7ab9679d64b556a7722f9eb7fa32d568ce8f329f89cca52e9'; \
	\
	cd /usr/src; \
	curl -O "$BISON_URL"; \
	echo "$BISON_SHA256 *$BISON_NAME.tar.xz" | sha256sum -c -; \
	tar -Jxf "$BISON_NAME.tar.xz"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
	; \
	\
	cd "$BISON_NAME"; \
	./configure --prefix=/usr/local; \
	make -j $(nproc) && make install; \
	make clean; \
	\
	cd /usr/src; \
	rm -rf /usr/src/bison*; \
	\
	docker-apt-prune /usr/local

RUN --mount=id=stretch,type=cache,target=/var/cache/apt,sharing=shared \
	--mount=id=stretch,type=cache,target=/var/lib/apt,sharing=shared \
	set -eux; \
	\
	GNUICONV_NAME="libiconv-1.15"; \
	GNUICONV_URL="http://ftp.gnu.org/pub/gnu/libiconv/$GNUICONV_NAME.tar.gz"; \
	GNUICONV_SHA256="ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178"; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	curl -O "$GNUICONV_URL"; \
	echo "$GNUICONV_SHA256 *$GNUICONV_NAME.tar.gz" | sha256sum -c -; \
	tar xzf "$GNUICONV_NAME.tar.gz"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
	; \
	\
	cd "$GNUICONV_NAME"; \
	./configure --prefix=/usr/local; \
	make -j $(nproc) && make install; \
	make clean; \
	ln -s /usr/local/lib/libiconv.so* /usr/lib/; \
	\
	cd /usr/src; \
	rm -rf /usr/src/libiconv*; \
	\
	docker-apt-prune /usr/local

ENV PHP_INI_DIR /usr/local/etc/php

RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV PHP_VERSION 5.3.29
ENV PHP_URL="https://www.php.net/distributions/php-5.3.29.tar.xz"
ENV PHP_SHA256="8438c2f14ab8f3d6cd2495aa37de7b559e33b610f9ab264f0c61b531bf0c262d"

RUN set -eux; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	curl -o php.tar.xz "$PHP_URL"; \
	echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -

RUN --mount=id=stretch,type=cache,target=/var/cache/apt,sharing=shared \
	--mount=id=stretch,type=cache,target=/var/lib/apt,sharing=shared \
	set -eux; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
		libcurl4-openssl-dev \
		libonig-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		zlib1g-dev \
	; \
	\
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	; \
	docker-php-source extract; \
	\
	cd /usr/src/php; \
	sed -i '48248,48261d' configure; \
	cd /usr/src/php/ext/iconv; \
	sed -i '41,47d' config.m4; \
	\
	cd /usr/src/php; \
	./configure \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--disable-cgi \
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
		--with-libxml-dir=/usr \
		--with-mhash \
		--with-onig \
		--with-openssl=/usr/local \
		--with-pear \
		--with-pic \
		--with-readline \
		--with-zlib \
		\
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
	; \
	make -j $(nproc); \
	find -type f -name '*.a' -delete; \
	make install; \
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
	docker-apt-prune /usr/local; \
	\
	php --version

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

RUN --mount=id=stretch,type=cache,target=/var/cache/apt,sharing=shared \
	--mount=id=stretch,type=cache,target=/var/lib/apt,sharing=shared \
	set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
		libbz2-dev \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libmcrypt-dev \
		libpng-dev \
		libvpx-dev \
		libxslt1-dev \
		libxpm-dev \
	; \
	\
	docker-php-source extract; \
	\
	docker-php-ext-configure \
		mysql \
		--with-mysql=mysqlnd \
	; \
	\
	docker-php-ext-configure \
		mysqli \
		--with-mysqli=mysqlnd \
	; \
	\
	docker-php-ext-configure \
		pdo_mysql \
		--with-pdo-mysql=mysqlnd \
	; \
	\
	ln -s /usr/lib/x86_64-linux-gnu/libXpm.* /usr/lib/; \
	\
	docker-php-ext-configure \
		gd \
		--enable-gd-native-ttf \
		--with-freetype-dir=/usr \
		--with-jpeg-dir=/usr \
		--with-png-dir=/usr \
		--with-xpm-dir=/usr \
		--with-zlib-dir \
	; \
	\
	docker-php-ext-install \
		bcmath \
		bz2 \
		exif \
		gd \
		gettext \
		mcrypt \
		mysql \
		mysqli \
		pdo_mysql \
		sockets \
		xsl \
		zip \
	; \
	\
	docker-apt-prune /usr/local

RUN --mount=id=stretch,type=cache,target=/var/cache/apt,sharing=shared \
	--mount=id=stretch,type=cache,target=/var/lib/apt,sharing=shared \
	set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
	; \
	\
	docker-php-source extract; \
	pecl update-channels; \
	\
	pear upgrade -Z pear/Archive_Tar; \
	\
	pecl install \
		redis-4.3.0 \
		timezonedb-2021.1 \
		ZendOpcache \
	; \
	chmod +x "$(php -r "echo ini_get('extension_dir');")"/*.so; \
	\
	docker-php-ext-enable \
		opcache \
		redis \
		timezonedb \
	; \
	\
	rm -rf /tmp/pear ~/.pearrc; \
	docker-apt-prune /usr/local

RUN set -eux; \
	\
	FILE_SHA256='5211584ad39af26704da9f6209bc5d8104a2d576e80ce9c7ed8368ddd779d0af'; \
	curl -o /usr/bin/composer https://getcomposer.org/download/2.2.21/composer.phar; \
	echo "$FILE_SHA256 */usr/bin/composer" | sha256sum -c -; \
	chmod u+x /usr/bin/composer; \
	\
	composer --version
