ARG FROM_ARCH=amd64
FROM alpine as qemu

RUN apk add --no-cache curl

RUN curl -fsSL https://github.com/multiarch/qemu-user-static/releases/download/v3.1.0-2/qemu-arm-static -O \
	&& chmod +x qemu-arm-static

RUN curl -fsSL https://github.com/multiarch/qemu-user-static/releases/download/v3.1.0-2/qemu-aarch64-static -O \
	&& chmod +x qemu-aarch64-static

# ----------------------------------------------------------------------------

ARG FROM_ARCH
FROM ${FROM_ARCH}/alpine:3.9 as libressl
COPY --from=qemu qemu-arm-static qemu-aarch64-static /usr/bin/

ENV LIBRESSL_VERSION="2.8.3"
ENV LIBRESSL_SHA="3967e08b3dc2277bf77057ea1f11148df7f96a2203cd21cf841902f2a1ec11320384a001d01fa58154d35612f7981bf89d5b1a60a2387713d5657677f76cc682"
ENV LIBRESSL_DOWNLOAD_URL="https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz"

# install build dependencies
RUN apk add --no-cache build-base curl file linux-headers

# work in temp dir
WORKDIR /tmp/src

# download, verify, extract, build, clean, strip
RUN curl -fsSL "${LIBRESSL_DOWNLOAD_URL}" -o libressl.tar.gz \
	&& echo "${LIBRESSL_SHA} *libressl.tar.gz" | sha512sum -c - \
	&& tar xzf libressl.tar.gz --strip-components=1 \
	&& rm -f libressl.tar.gz \
	&& CFLAGS="-DLIBRESSL_APPS=off -DLIBRESSL_TESTS=off" \
		./configure --prefix=/opt/libressl --enable-static=no \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf \
		/opt/libressl/share \
		/opt/libressl/include\* \
		/opt/libressl/lib/libtls.* \
		/opt/libressl/bin/ocspcheck \
		/opt/libressl/lib/pkgconfig \
		/opt/libressl/lib/*.la \
	&& strip --strip-all \
		/opt/libressl/bin/* \
		/opt/libressl/lib/lib*

# ----------------------------------------------------------------------------

ARG FROM_ARCH
FROM ${FROM_ARCH}/alpine:3.9 as unbound
COPY --from=qemu qemu-arm-static qemu-aarch64-static /usr/bin/

ENV UNBOUND_VERSION="1.9.0"
ENV UNBOUND_SHA="7dfa8e078507fc24a2d0938eea590389453bacfcac023f1a41af19350ea1f7b87d0c82d7eead121a11068921292a96865e177274ff27ed8b8868445f80f7baf6"
ENV UNBOUND_DOWNLOAD_URL="https://www.unbound.net/downloads/unbound-${UNBOUND_VERSION}.tar.gz"

# create unbound group and user
RUN addgroup unbound && adduser -D -H -s /sbin/nologin -G unbound unbound

# install build dependencies
RUN apk add --no-cache build-base curl file linux-headers libevent libevent-dev expat expat-dev

# work in temp dir
WORKDIR /tmp/src

# copy libressl
COPY --from=libressl /opt/libressl /opt/libressl

# download, verify, extract, build, clean, strip
RUN curl -fsSL "${UNBOUND_DOWNLOAD_URL}" -o unbound.tar.gz \
	&& echo "${UNBOUND_SHA} *unbound.tar.gz" | sha512sum -c - \
	&& tar xzf unbound.tar.gz --strip-components=1 \
	&& rm -f unbound.tar.gz \
	&& RANLIB="gcc-ranlib" \
		./configure --prefix=/opt/unbound --with-pthreads \
		--with-username=unbound --with-ssl=/opt/libressl --with-libevent \
		--enable-event-api --enable-static=no --enable-pie  --enable-relro-now \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example \
	&& rm -rf \
		/opt/unbound/share \
		/opt/unbound/include \
		/opt/unbound/lib/pkgconfig \
		/opt/unbound/lib/*.la \
	&& strip --strip-all \
		/opt/unbound/lib/lib* \
		/opt/unbound/sbin/unbound \
		/opt/unbound/sbin/unbound-anchor \
		/opt/unbound/sbin/unbound-checkconf \
		/opt/unbound/sbin/unbound-control \
		/opt/unbound/sbin/unbound-host

# ----------------------------------------------------------------------------

ARG FROM_ARCH
FROM ${FROM_ARCH}/alpine:3.9
COPY --from=qemu qemu-arm-static qemu-aarch64-static /usr/bin/

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL maintainer="kylemharding@gmail.com"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="klutchell/unbound"
LABEL org.label-schema.description="Unbound is a validating, recursive, caching DNS resolver"
LABEL org.label-schema.url="https://unbound.net/"
LABEL org.label-schema.vcs-url="https://github.com/klutchell/unbound"
LABEL org.label-schema.docker.cmd="docker run -p 53:53/tcp -p 53:53/udp klutchell/unbound"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.version="${BUILD_VERSION}"
LABEL org.label-schema.vcs-ref="${VCS_REF}"

# create unbound group and user
RUN addgroup unbound && adduser -D -H -s /sbin/nologin -G unbound unbound

# install runtime dependencies
RUN apk add --no-cache libevent expat curl drill ca-certificates

# copy libressl and unbound
COPY --from=unbound /opt/ /opt/

# work in unbound root directory
WORKDIR /opt/unbound/etc/unbound

# copy default config file
COPY a-records.conf unbound.conf ./

# copy startup script
COPY startup.sh /

# set execute bit
RUN chmod +x /startup.sh

# add unbound binaries to path
ENV PATH /opt/unbound/sbin:"${PATH}"

# expose dns ports
EXPOSE 53/tcp 53/udp

# run startup script
CMD [ "/bin/sh", "-xe", "/startup.sh" ]