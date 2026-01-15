# Build and Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Suricata IDS/NSM"

COPY dist/ /root/dist/

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache add \
    ca-certificates \
    curl \
    file \
    hiredis \
    libcap \
    wget \
    suricata && \
    # Setup user and app
    addgroup -g 2000 suri && \
    adduser -S -H -u 2000 -D -g 2000 suri && \
    cp /root/dist/*.yaml /etc/suricata/ && \
    cp /root/dist/*.conf /etc/suricata/ && \
    cp /root/dist/*.bpf /etc/suricata/ && \
    cp /root/dist/update.sh /usr/bin/ && \
    chmod 644 /etc/suricata/*.config && \
    chmod 755 -R /var/lib/suricata && \
    chmod 755 /usr/bin/update.sh && \
    chown -R root:suri /tmp /run && \
    # Initial rule update
    suricata-update update-sources && \
    suricata-update --no-test --no-reload && \
    # Clean up
    rm -rf /root/* /tmp/* /var/cache/apk/*

# Start suricata
STOPSIGNAL SIGINT

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
    CMD pgrep suricata || exit 1

WORKDIR /etc/suricata
ENTRYPOINT ["/bin/bash", "-c", "SURICATA_CAPTURE_FILTER=$(/usr/bin/update.sh $OINKCODE) && exec suricata -v -F $SURICATA_CAPTURE_FILTER -i eth0"]
