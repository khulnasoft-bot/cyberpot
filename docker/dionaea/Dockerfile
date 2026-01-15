# Build stage
FROM ubuntu:24.04 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Dionaea Builder"

ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    check \
    cmake \
    cython3 \
    git \
    libcap2-bin \
    libcurl4-openssl-dev \
    libev-dev \
    libglib2.0-dev \
    libloudmouth1-dev \
    libnetfilter-queue-dev \
    libnl-3-dev \
    libpcap-dev \
    libssl-dev \
    libtool \
    libudns-dev \
    python3 \
    python3-dev \
    python3-setuptools \
    wget && \
    ARCH=$(arch) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    wget https://snapshot.debian.org/archive/debian/20170317T220000Z/pool/main/libe/libemu/libemu2_0.2.0+git20120122-1.2+b1_$ARCH.deb \
    https://snapshot.debian.org/archive/debian/20170317T220000Z/pool/main/libe/libemu/libemu-dev_0.2.0+git20120122-1.2+b1_$ARCH.deb && \
    apt-get install ./libemu2_0.2.0+git20120122-1.2+b1_$ARCH.deb \
    ./libemu-dev_0.2.0+git20120122-1.2+b1_$ARCH.deb -y

# Get and install dionaea
RUN git clone https://github.com/t3chn0m4g3/dionaea -b 0.11.1 /root/dionaea/ && \
    cd /root/dionaea && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/dionaea .. && \
    make && \
    make install

# Runtime stage
FROM ubuntu:24.04

LABEL maintainer="CyberPot Team"
LABEL description="Dionaea Honeypot"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-boto3 \
    python3-bson \
    python3-psutil \
    python3-yaml \
    libcurl4 \
    libev4 \
    libglib2.0-0 \
    libnetfilter-queue1 \
    libnl-3-200 \
    libpcap0.8 \
    libpython3.12 \
    libcap2-bin \
    libudns0 && \
    rm -rf /var/lib/apt/lists/*

# Setup user
RUN addgroup --gid 2000 dionaea && \
    adduser --system --no-create-home --shell /bin/bash --uid 2000 --disabled-password --disabled-login --gid 2000 dionaea

COPY --from=builder /opt/dionaea /opt/dionaea
COPY --from=builder /usr/lib/libemu.so.2 /usr/lib/libemu.so.2

COPY dist/ /root/dist/
RUN mkdir -p /opt/dionaea/etc/dionaea && \
    mv /root/dist/etc/* /opt/dionaea/etc/dionaea/ && \
    cp /root/dist/cpu_check.py / && \
    chown -R dionaea:dionaea /opt/dionaea/var && \
    setcap cap_net_bind_service=+ep /opt/dionaea/sbin/dionaea

# Start dionaea
STOPSIGNAL SIGINT

# Dionaea sometimes hangs at 100% CPU usage, if detected container will become unhealthy and restarted by cyberpotinit
HEALTHCHECK --interval=5m --timeout=30s --retries=3 CMD python3 /cpu_check.py $(pgrep -of dionaea) 99

USER dionaea:dionaea
WORKDIR /opt/dionaea
CMD ["/opt/dionaea/sbin/dionaea", "-u", "dionaea", "-g", "dionaea", "-c", "/opt/dionaea/etc/dionaea/dionaea.cfg"]