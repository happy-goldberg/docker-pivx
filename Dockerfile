FROM alpine:3.7

MAINTAINER Andreas Lingenhag <11538311+alingenhag@users.noreply.github.com

# switch to root, let the entrypoint drop back to pivx user
USER root
ENV USER pivx
ARG PIVX_VERSION

# runtime dependencies
RUN apk --no-cache add \
  su-exec 

# build time dependencies
RUN apk --no-cache add --virtual .build-dependencies \
  wget \
  gnupg \
  build-base \
  autoconf \
  automake \
  libtool \
  boost-dev \
  libressl-dev \
  db-dev \
  miniupnpc-dev \
  qt5-qtbase-dev \
  qt5-qttools-dev \
  protobuf-dev \
  libqrencode-dev \
  libevent-dev \
  chrpath

WORKDIR /tmp

# add pivx user to the system
RUN adduser -h /home/"${USER}" -s /bin/sh -G users -D "${USER}"

# download source
RUN wget -O /tmp/pivx-"${PIVX_VERSION}".tar.gz "https://github.com/PIVX-Project/PIVX/releases/download/v"${PIVX_VERSION}"/pivx-"${PIVX_VERSION}".tar.gz" \
  && wget -O /tmp/SHA256SUMS.asc "https://github.com/PIVX-Project/PIVX/releases/download/v"${PIVX_VERSION}"/SHA256SUMS.asc"

# verify sha hash
ADD https://raw.githubusercontent.com/f-u-z-z-l-e/docker-coin-scripts/master/alpine/verify-sha256.sh /tmp/
RUN chmod +x verify-sha256.sh && ./verify-sha256.sh SHA256SUMS.asc pivx-"${PIVX_VERSION}".tar.gz

# verify gpg signature
RUN gpg --keyserver-options auto-key-retrieve --verify SHA256SUMS.asc 

# compile binaries
RUN tar xzpvf pivx-"${PIVX_VERSION}".tar.gz \
  && cd pivx-"${PIVX_VERSION}" \
  && ./autogen.sh \
  && ./configure --with-incompatible-bdb --with-libressl \
  && make -j8 \
  && make install \
  && cd ~ && rm -rf /tmp/pivx-"${PIVX_VERSION}"

# Remove packages that were only used at build time
#RUN apk del .build-dependencies 

EXPOSE 51470 51472

WORKDIR /home/"${USER}"

# add startup scripts
ADD ./scripts /usr/local/bin
ENTRYPOINT ["entrypoint.sh"] 
CMD ["start-unprivileged.sh"]

