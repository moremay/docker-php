FROM php:8.4-cli-alpine

COPY packages /phpcs/packages
COPY vendor /phpcs/vendor
COPY composer* /phpcs/
COPY phpcs.xml* /phpcs/
COPY run /phpcs/

WORKDIR /www
ENTRYPOINT [ "/phpcs/run" ]
CMD [ ]
