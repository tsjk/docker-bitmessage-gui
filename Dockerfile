FROM debian:buster

ENV DEBIAN_FRONTEND="noninteractive" \
    TZ="Etc/UTC" \
    SOCKS_HOST="" \
    SOCKS_PORT=""

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
 && echo "${TZ}" > /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata \
 && apt-get update \
 && apt-get install -y apt-utils \
 && apt-get install -y software-properties-common locales \
 && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && echo 'LANG="en_US.UTF-8"' > /etc/default/locale \
 && dpkg-reconfigure --frontend=noninteractive locales \
 && update-locale LANG=en_US.UTF-8 \

# Set the locale
ENV LANG=en_US.UTF-8\
    LANGUAGE=en_US.UTF-8\
    LC_ALL=en_US.UTF-8

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64 /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64.asc /tini.asc
COPY ./0001-shutdown.patch /tmp/0001-shutdown.patch
COPY ./entrypoint.sh /entrypoint.sh

RUN add-apt-repository 'deb http://deb.debian.org/debian buster-backports main' \
 && apt-get dist-upgrade -y \
 && apt-get install -y \
      python \
      python-setuptools \
      python-msgpack \
      python-qt4 \
      python-six \
      python-stem \
      python-jsonrpclib \
      python-defusedxml \
      python-qrcode \
      socat \
 && apt-get install -y \
      libssl-dev \
      g++ \
      git \
      gpg \
 && gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 \
      --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --batch --verify /tini.asc /tini && rm /tini.asc \
 && rm -rf /root/.gnupg \
 && chmod 0755 /tini /entrypoint.sh \
 && git clone https://github.com/Bitmessage/PyBitmessage \
 && ( cd PyBitmessage && \
      patch -p0 < /tmp/0001-shutdown.patch && \
      python setup.py install ) \
 && rm -rf PyBitmessage \
 && rm -f /tmp/0001-shutdown.patch \
 && apt-get purge --auto-remove -y \
      libssl-dev \
      g++ \
      git \
      gpg \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -u 1001 --create-home --home-dir /home/user user \
 && mkdir /PyBitmessage--data \
 && mkdir /home/user/.config \
 && ln -s /PyBitmessage--data /home/user/.config/PyBitmessage

USER user
WORKDIR /home/user
VOLUME ["PyBitmessage--data"]
ENTRYPOINT ["/tini", "-g", "--", "/entrypoint.sh"]
CMD ["pybitmessage"]
