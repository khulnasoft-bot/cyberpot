# Stage 1: Download and prepare Kibana
FROM node:22.21.1-alpine3.23 AS builder
ENV KB_VER=9.2.3

RUN apk --no-cache add aria2 curl tar && \
    ARCH=$(arch) && \
    if [ "$ARCH" = "x86_64" ]; then KB_ARCH="x86_64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then KB_ARCH="aarch64"; fi && \
    aria2c -s 16 -x 16 https://artifacts.elastic.co/downloads/kibana/kibana-$KB_VER-linux-$KB_ARCH.tar.gz && \
    mkdir -p /usr/share/kibana && \
    tar xvfz kibana-$KB_VER-linux-$KB_ARCH.tar.gz --strip-components=1 -C /usr/share/kibana/

# Stage 2: Final image
FROM node:22.21.1-alpine3.23
LABEL org.opencontainers.image.authors="KhulnaSoft" \
    org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot" \
    org.opencontainers.image.title="CyberPot Kibana" \
    org.opencontainers.image.description="Kibana for CyberPot ELK Stack"

ENV KB_VER=9.2.3

# Copy Kibana from builder
COPY --from=builder /usr/share/kibana /usr/share/kibana
# Copy dist files
COPY dist/ /root/dist/

RUN apk --no-cache -U upgrade && \
    apk --no-cache add curl gcompat && \
    # Kibana's bundled node does not work in build pipeline
    rm -rf /usr/share/kibana/node/glibc-217/bin/node && \
    ln -s /usr/local/bin/node /usr/share/kibana/node/glibc-217/bin/node && \
    # Setup configs
    sed -i 's/#server.basePath: ""/server.basePath: "\/kibana"/' /usr/share/kibana/config/kibana.yml && \
    sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /usr/share/kibana/config/kibana.yml && \
    sed -i 's/#elasticsearch.hosts: \["http:\/\/localhost:9200"\]/elasticsearch.hosts: \["http:\/\/elasticsearch:9200"\]/' /usr/share/kibana/config/kibana.yml && \
    sed -i 's/#server.rewriteBasePath: false/server.rewriteBasePath: false/' /usr/share/kibana/config/kibana.yml && \
    echo "xpack.reporting.roles.enabled: false" >> /usr/share/kibana/config/kibana.yml && \
    echo "elasticsearch.requestTimeout: 60000" >> /usr/share/kibana/config/kibana.yml && \
    echo "elasticsearch.shardTimeout: 60000" >> /usr/share/kibana/config/kibana.yml && \
    echo "unifiedSearch.autocomplete.valueSuggestions.timeout: 60000" >> /usr/share/kibana/config/kibana.yml && \
    echo "unifiedSearch.autocomplete.valueSuggestions.terminateAfter: 1000000" >> /usr/share/kibana/config/kibana.yml && \
    # Optimize
    rm -rf /usr/share/kibana/optimize/bundles/* && \
    /usr/share/kibana/bin/kibana --optimize --allow-root && \
    # Setup user
    addgroup -g 2000 kibana && \
    adduser -S -H -s /bin/ash -u 2000 -D -g 2000 kibana && \
    chown -R kibana:kibana /usr/share/kibana/data && \
    chmod 755 -R /usr/share/kibana/config && \
    # Clean up
    rm -rf /root/* /tmp/* /var/cache/apk/*

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD curl -s -XGET 'http://127.0.0.1:5601' || exit 1

# Start kibana
STOPSIGNAL SIGKILL
USER kibana:kibana
CMD ["/usr/share/kibana/bin/kibana"]