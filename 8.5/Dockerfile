ARG mirrors=
ARG gnu_mirrors=http://ftp.gnu.org/pub/gnu
ARG TZ=

FROM alpine:3.23 AS builder

ARG mirrors
ARG gnu_mirrors
ARG TZ

COPY docker-* /usr/local/bin/
COPY x86_64 /usr/src/repo/x86_64

RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories; \
	if [ -n "${mirrors}" ]; then \
		sed "s/dl-cdn.alpinelinux.org/${mirrors}/g" -i /etc/apk/repositories; \
	fi; \
	echo '/usr/src/repo/' >> /etc/apk/repositories

RUN apk add --allow-untrusted --no-cache \
	busybox~1.37.0-r31 \
	zlib-dev~1.3.1-r10 \
	curl~8.18.0-r0

ENV PHPIZE_DEPS="autoconf file g++ gcc libc-dev make pkgconf re2c patch dpkg-dev dpkg"
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

RUN set -ex; \
	docker-lib download /usr/src/php \
		"https://www.php.net/distributions/php-8.5.2.tar.xz" \
		"cb75a9b00a2806f7390dd64858ef42a47b443b3475769c8af6af33a18b1381f1"

ENV TZ=${TZ:-Asia/Shanghai}
ENV PHP_VERSION=8.5.2
ENV PHP_INI_DIR=/usr/local/etc/php

RUN set -eux; \
	. docker-lib php-init \
		argon2-dev \
		coreutils \
		gnu-libiconv-dev \
		libsodium-dev \
		libxml2-dev \
		linux-headers \
		oniguruma-dev \
		openssl-dev \
		readline-dev \
		sqlite-dev \
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
		--with-mhash \
		--with-pic \
		--with-password-argon2 \
		--with-sodium=shared \
		\
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		\
		--with-iconv=/usr \
		--with-libxml \
		--with-openssl \
		--with-pear \
		--with-readline \
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
		postgresql17-dev \
		unixodbc-dev \
	; \
	\
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
	sed -e "s#<ext/standard/php_smart_string.h>#<Zend/zend_smart_string.h>#" -i ext/redis/common.h; \
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
RUN rm -rf /usr/src/repo

FROM scratch
LABEL org.opencontainers.image.authors="moremay"
LABEL org.opencontainers.image.source="https://github.com/moremay/docker-php"
LABEL org.opencontainers.image.licenses="MIT"

ARG TZ

ENV TZ=${TZ:-Asia/Shanghai}
ENV PHP_VERSION=8.5.2
ENV PHP_INI_DIR=/usr/local/etc/php

ENV PHPIZE_DEPS="autoconf file g++ gcc libc-dev make pkgconf re2c patch dpkg-dev dpkg"
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
