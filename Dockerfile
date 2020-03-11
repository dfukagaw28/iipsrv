FROM debian:buster-slim AS build

ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/dfukagaw28/iipsrv.git" \
      org.label-schema.schema-version="1.0"

ENV PYTHONUNBUFFERED 1

ENV IIPSRV_BUILD_DEPS \
        autoconf \
        automake \
        ca-certificates \
        curl \
        g++ \
        gawk \
        libtool \
        make \
        pkg-config

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        $IIPSRV_BUILD_DEPS \
        libfcgi-dev \
        libjpeg-dev \
        libmemcached-dev \
        libopenjp2-7-dev \
        libtiff-dev

WORKDIR /usr/local/src/iipsrv

COPY Makefile.am acinclude.m4 autogen.sh configure.ac ./
COPY fcgi ./fcgi
COPY man ./man
COPY src ./src
COPY windows ./windows

RUN set -ex \
    && ./autogen.sh \
    && ./configure --enable-openjpeg \
    && make


FROM debian:buster-slim

COPY --from=build /usr/local/src/iipsrv/src/iipsrv.fcgi /usr/local/bin/iipsrv.fcgi

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libfcgi \
        libgomp1 \
        libjpeg62-turbo \
        libmemcached11 \
        libopenjp2-7 \
        libtiff5 \
        lighttpd \
    && mkdir -p /var/run/lighttpd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY docker-files/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]

EXPOSE 80

RUN set -ex \
    && ln -sfT /dev/stderr "/var/log/lighttpd/error.log" \
    && ln -sfT /dev/stderr "/var/log/lighttpd/access.log" \
    && ln -sfT /dev/stderr "/var/log/iipsrv.log"
