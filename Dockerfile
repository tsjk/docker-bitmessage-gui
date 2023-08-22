FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive

ENV TZ=Etc/UTC

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

COPY ./0001-shutdown.patch /tmp/0001-shutdown.patch

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
 && apt-get install -y \
      g++ \
      git \
      libssl-dev \
 && git clone https://github.com/Bitmessage/PyBitmessage \
 && ( cd PyBitmessage && \
      patch -p0 < /tmp/0001-shutdown.patch && \
      python setup.py install ) \
 && rm -rf PyBitmessage \
 && rm -f /tmp/0001-shutdown.patch \
 && apt-get purge --auto-remove -y \
      g++ \
      git \
      libssl-dev \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -u 1001 --create-home --home-dir /home/user user \
 && mkdir /PyBitmessage--data \
 && mkdir /home/user/.config \
 && ln -s /PyBitmessage--data /home/user/.config/PyBitmessage

USER user
WORKDIR /home/user
VOLUME ["PyBitmessage--data"]
ENTRYPOINT ["pybitmessage"]
