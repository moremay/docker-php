FROM moremay/php:8
LABEL org.opencontainers.image.authors="moremay"
LABEL org.opencontainers.image.source="https://github.com/moremay/docker-php"
LABEL org.opencontainers.image.licenses="MIT"

COPY packages /phpcs/packages
COPY vendor /phpcs/vendor
COPY composer* /phpcs/
COPY phpcs.xml* /phpcs/
COPY run /phpcs/

WORKDIR /www
ENTRYPOINT [ "/phpcs/run" ]
CMD [ ]
