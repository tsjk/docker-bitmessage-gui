FROM debian:jessie

RUN apt-get update && apt-get install -y \
    python \
    python-msgpack \
    python-qt4 \
    python-setuptools \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    g++ \
    git \
    libssl-dev \
 && git clone https://github.com/Bitmessage/PyBitmessage \
 && cd PyBitmessage \
 && git checkout 0.6.3.2 \
 && python setup.py install \
 && cd .. \
 && rm -rf PyBitmessage \
 && apt-get purge --auto-remove -y \
    g++ \
    git \
    libssl-dev \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --home-dir /home/user user \
 && mkdir /data \
 && mkdir /home/user/.config \
 && ln -s /data /home/user/.config/PyBitmessage

WORKDIR /home/user
USER user
ENTRYPOINT ["pybitmessage"]
