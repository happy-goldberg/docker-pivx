FROM ubuntu:xenial

MAINTAINER Andreas Lingenhag <11538311+alingenhag@users.noreply.github.com

# switch to root, let the entrypoint drop back to pivx user
USER root
ENV USER pivx
ARG VERSION

RUN apt-get update && apt-get install -y software-properties-common \
 && apt-add-repository ppa:bitcoin/bitcoin \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    automake \
    bsdmainutils \
    git \
    gnupg2 \
    libboost-all-dev \
    libdb4.8-dev \
    libdb4.8++-dev \
    libevent-dev \
    libssl-dev \
    libtool \
    pkg-config \
    wget

WORKDIR /tmp

#install su-exec
RUN git clone https://github.com/ncopa/su-exec.git \
 && cd su-exec && make && cp su-exec /usr/local/bin/ \
 && cd .. && rm -rf su-exec

# add pivx user to the system
RUN useradd -d /home/"${USER}" -s /bin/sh -G users "${USER}"

# download source
RUN wget -O /tmp/pivx-"${VERSION}".tar.gz "https://github.com/PIVX-Project/PIVX/releases/download/v"${VERSION}"/pivx-"${VERSION}".tar.gz" \
 && wget -O /tmp/SHA256SUMS.asc "https://github.com/PIVX-Project/PIVX/releases/download/v"${VERSION}"/SHA256SUMS.asc"

# verify sha hash
ADD https://raw.githubusercontent.com/f-u-z-z-l-e/docker-coin-scripts/master/alpine/verify-sha256.sh /tmp/
RUN chmod +x verify-sha256.sh && ./verify-sha256.sh SHA256SUMS.asc pivx-"${VERSION}".tar.gz

# verify gpg signature
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 3BDCDA2D87A881D9
RUN gpg --keyserver-options auto-key-retrieve --verify SHA256SUMS.asc

# compile binaries
RUN tar xzpvf pivx-"${VERSION}".tar.gz \
  && cd pivx-"${VERSION}" \
  && ./autogen.sh \
  && ./configure \
  && make -j8 \
  && make install \
&& cd ~ && rm -rf /tmp/pivx-"${VERSION}"

EXPOSE 51470

WORKDIR /home/"${USER}"

# add startup scripts
ADD ./scripts /usr/local/bin
ENTRYPOINT ["entrypoint.sh"]
CMD ["start-unprivileged.sh"]

