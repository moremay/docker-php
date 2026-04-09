FROM moremay/php:8
LABEL org.opencontainers.image.authors="moremay"
LABEL org.opencontainers.image.source="https://github.com/moremay/docker-php"
LABEL org.opencontainers.image.licenses="MIT"

COPY phpcs/packages /phpcs/packages
COPY phpcs/vendor /phpcs/vendor
COPY phpcs/composer* /phpcs/
COPY phpcs/phpcs.xml* /phpcs/
COPY phpcs/run /phpcs/

WORKDIR /www
ENTRYPOINT [ "/phpcs/run" ]
CMD [ ]
