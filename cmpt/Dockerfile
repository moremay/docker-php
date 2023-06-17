FROM php:7.4.33-cli-alpine

RUN set -eux; \
	\
	FILE_SHA256="$(curl https://getcomposer.org/download/latest-stable/composer.phar.sha256)"; \
	curl -o /usr/bin/composer https://getcomposer.org/download/latest-stable/composer.phar; \
	echo "$FILE_SHA256 */usr/bin/composer" | sha256sum -c -; \
	chmod u+x /usr/bin/composer; \
	\
	composer --version

ENV COMPOSER_ALLOW_SUPERUSER 1

RUN set -eux; \
	mkdir -p /cmpt; \
	cd /cmpt; \
	echo "{}" >composer.json; \
	composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true; \
	composer require --dev dealerdirect/phpcodesniffer-composer-installer:"^0.7" phpcompatibility/phpcompatibility-all:"*"; \
	ln -s /cmpt/vendor/bin/* /usr/bin/; \
	phpcs -i | grep -wqs "PHPCompatibility"
