FROM alpine:3.20.3

# Metadata
LABEL maintainer="KhulnaSoft Security <security@khulnasoft.com>"
LABEL org.opencontainers.image.title="cyberpotinit"
LABEL org.opencontainers.image.description="Initialisation and monitoring container for CyberPot"
LABEL org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot"

# Include dist
COPY dist/ /opt/cyberpot/

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    aria2 \
    apache2-utils \
    bash \
    bind-tools \
    conntrack-tools \
    cracklib \
    curl \
    ethtool \
    figlet \
    git \
    grep \
    iproute2 \
    iptables \
    jq \
    logrotate \
    lsblk \
    net-tools \
    openssl \
    pigz \
    tar \
    uuidgen \
    yq-go && \
    # Setup user, logrotate permissions
    addgroup -g 2000 cyberpot && \
    adduser -S -s /bin/ash -u 2000 -D -g 2000 cyberpot && \
    chmod 0600 /opt/cyberpot/etc/logrotate/logrotate.conf && \
    # Clean up
    apk del --purge git && \
    rm -rf /root/* /tmp/* \
    /root/.cache \
    /opt/cyberpot/.git \
    /var/cache/apk/*

WORKDIR /opt/cyberpot

# HEALTHCHECK to verify successful initialization or autoheal running
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD test -f /tmp/success || pgrep -f autoheal || exit 1

STOPSIGNAL SIGTERM

# Using ENTRYPOINT so we can catch SIGTERM for cleanup
ENTRYPOINT ["/opt/cyberpot/entrypoint.sh"]
