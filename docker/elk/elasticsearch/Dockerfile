# Stage 1: Download and prepare Elasticsearch
FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
ENV ES_VER=8.17.3

RUN apt-get update && \
    apt-get install -y aria2 curl && \
    ARCH=$(arch) && \
    if [ "$ARCH" = "x86_64" ]; then ES_ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ES_ARCH="arm64"; fi && \
    aria2c -s 16 -x 16 https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ES_VER-$ES_ARCH.deb -o elasticsearch.deb

# Stage 2: Final image
FROM ubuntu:24.04
LABEL org.opencontainers.image.authors="KhulnaSoft" \
    org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot" \
    org.opencontainers.image.title="CyberPot Elasticsearch" \
    org.opencontainers.image.description="Elasticsearch for CyberPot ELK Stack"

ENV DEBIAN_FRONTEND=noninteractive
ENV ES_VER=8.17.3

# Copy deb from builder and config from dist
COPY --from=builder /elasticsearch.deb /tmp/elasticsearch.deb
COPY dist/elasticsearch.yml /etc/elasticsearch/

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y adduser curl && \
    dpkg --force-confold -i /tmp/elasticsearch.deb && \
    # Setup user, groups and configs
    groupmod -g 2000 elasticsearch && \
    usermod -u 2000 elasticsearch && \
    chown -R root:elasticsearch /etc/default/elasticsearch \
    /etc/elasticsearch && \
    chown -R elasticsearch:elasticsearch /var/lib/elasticsearch \
    /var/log/elasticsearch && \
    # Clean up
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    /tmp/* /var/tmp/* \
    /root/.cache

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD curl -s -XGET 'http://127.0.0.1:9200/_cat/health' || exit 1

# Start ELK
USER elasticsearch:elasticsearch
CMD ARCH=$(arch) && \
    if [ "$ARCH" = "aarch64" ]; then export _JAVA_OPTIONS="-XX:UseSVE=0"; fi && \
    exec /usr/share/elasticsearch/bin/elasticsearch
