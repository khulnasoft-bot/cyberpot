# Stage 1: Download and prepare Logstash and assets
FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
ENV LS_VER=8.17.3

RUN apt-get update && \
    apt-get install -y aria2 curl bzip2 && \
    # Determine arch
    ARCH=$(arch) && \
    if [ "$ARCH" = "x86_64" ]; then LS_ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then LS_ARCH="arm64"; fi && \
    # Download Logstash
    aria2c -s 16 -x 16 https://artifacts.elastic.co/downloads/logstash/logstash-$LS_VER-$LS_ARCH.deb -o logstash.deb && \
    # Download CVE and IPRep databases
    mkdir -p /etc/listbot && \
    cd /etc/listbot && \
    aria2c -s 16 -x 16 https://listbot.sicherheitstacho.eu/cve.yaml.bz2 && \
    aria2c -s 16 -x 16 https://listbot.sicherheitstacho.eu/iprep.yaml.bz2 && \
    bunzip2 *.bz2

# Stage 2: Final image
FROM ubuntu:24.04
LABEL org.opencontainers.image.authors="KhulnaSoft" \
    org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot" \
    org.opencontainers.image.title="CyberPot Logstash" \
    org.opencontainers.image.description="Logstash for CyberPot ELK Stack"

ENV DEBIAN_FRONTEND=noninteractive
ENV LS_VER=8.17.3

# Copy deb and assets from builder
COPY --from=builder /logstash.deb /tmp/logstash.deb
COPY --from=builder /etc/listbot /etc/listbot
# Copy dist files
COPY dist/ /root/dist/

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y adduser bash curl && \
    dpkg -i /tmp/logstash.deb && \
    # Add and move files
    cp /root/dist/entrypoint.sh /usr/bin/ && \
    chmod u+x /usr/bin/entrypoint.sh && \
    mkdir -p /usr/share/logstash/config && \
    cp /root/dist/logstash.conf /etc/logstash/ && \
    cp /root/dist/http_input.conf /etc/logstash/ && \
    cp /root/dist/http_output.conf /etc/logstash/ && \
    cp /root/dist/pipelines.yml /usr/share/logstash/config/pipelines.yml && \
    cp /root/dist/pipelines_sensor.yml /usr/share/logstash/config/pipelines_sensor.yml && \
    cp /root/dist/cyberpot-template.json /etc/logstash/ && \
    cd /usr/share/logstash && \
    bin/logstash-plugin update logstash-filter-translate && \
    rm -f /etc/logstash/pipelines.yml /etc/logstash/logstash.yml && \
    # Setup user, groups and configs
    groupmod -g 2000 logstash && \
    usermod -u 2000 logstash && \
    chown -R logstash:logstash /etc/listbot \
    /var/log/logstash/ \
    /var/lib/logstash \
    /usr/share/logstash/data \
    /usr/share/logstash/config/pipelines* && \
    chmod 755 /usr/bin/entrypoint.sh && \
    # Clean up
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    /tmp/* /var/tmp/* \
    /root/.cache \
    /root/*

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD curl -s -XGET 'http://127.0.0.1:9600' || exit 1

# Start logstash
USER logstash:logstash
CMD ["entrypoint.sh"]
