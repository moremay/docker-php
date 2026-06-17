FROM alpine

RUN --mount=type=cache,id=apk-cache,target=/apk-cache \
    set -e; \
    apk add --cache-dir /apk-cache rsync; \
    mkdir -p /download /sync-cache

# build: .download -> /sync-cache ; build cache -> /sync-cache -> build cache

COPY .download/* /sync-cache/

# 不同值产生刷新，使 RUN 始终运行
ARG CACHE_BUST

RUN --mount=type=cache,id=download,target=/download \
    set -ex; \
    \
    cd /download; \
    test -f /sync-cache/.delete && cat /sync-cache/.delete | tr '\n' '\0' | xargs -r0 rm -f ; \
    rm -f .delete .git*; \
    \
    cd /sync-cache; \
    test -f /sync-cache/.delete && cat /sync-cache/.delete | tr '\n' '\0' | xargs -r0 rm -f ; \
    rm -f .delete .git*; \
    \
    rsync -rutU /download/ /sync-cache/; \
    rsync -rutU /sync-cache/ /download/

# run: /sync-cache -> .download
CMD [ "rsync", "-rutUhv", "--info=progress2", "/sync-cache/", "/download/" ]
