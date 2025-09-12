ARG composer=
ARG mirrors=
ARG gnu_mirrors=http://ftp.gnu.org/pub/gnu

FROM alpine:3.10.9

ARG composer
ARG mirrors
ARG gnu_mirrors

COPY docker-* /usr/local/bin/

ENV PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c"

RUN if [ -n "${mirrors}" ]; then \
		sed "s/dl-cdn.alpinelinux.org/${mirrors}/g" -i /etc/apk/repositories; \
	fi

RUN apk add --update --no-cache \
		ca-certificates \
		curl \
		tar \
		xz \
	; \
	update-ca-certificates

RUN set -eux; \
	addgroup -g 82 -S www-data; \
	adduser -u 82 -D -S -G www-data www-data

RUN set -eux; \
	\
	OPENSSL_NAME='openssl-1.0.2u'; \
	OPENSSL_URL="https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_2u/openssl-1.0.2u.tar.gz"; \
	OPENSSL_SHA256='ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16'; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	curl -LkO "$OPENSSL_URL"; \
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
	GNUICONV_NAME="libiconv-1.18"; \
	GNUICONV_URL="${gnu_mirrors}/libiconv/$GNUICONV_NAME.tar.gz"; \
	GNUICONV_SHA256="3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8"; \
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
	\
	docker-apk-prune /usr/local

ENV PHP_INI_DIR=/usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV PHP_VERSION=5.3.29
ENV PHP_URL="https://www.php.net/distributions/php-5.3.29.tar.xz"
ENV PHP_SHA256="8438c2f14ab8f3d6cd2495aa37de7b559e33b610f9ab264f0c61b531bf0c262d"

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
		coreutils \
		curl-dev \
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
		--with-openssl \
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
	sed -i 's#^;date\.timezone.*$#date.timezone = "Asia/Shanghai"#' "$PHP_INI_DIR/php.ini"

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
		libvpx-dev \
		libxpm-dev \
		libxslt-dev \
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
		--with-freetype-dir \
		--with-jpeg-dir \
		--with-png-dir \
		--with-xpm-dir \
		--with-zlib-dir \
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
	docker-apk-prune

RUN set -eux; \
	if [ "${composer}" == "yes" ]; then \
		FILE_SHA256='8b3f41253363f0645402d1951d6e7f02adedeef29c16de6074763e463e25c23f'; \
		curl -o /usr/bin/composer https://getcomposer.org/download/2.2.25/composer.phar; \
		echo "$FILE_SHA256 */usr/bin/composer" | sha256sum -c -; \
		chmod u+x /usr/bin/composer; \
		\
		composer --version; \
	fi
