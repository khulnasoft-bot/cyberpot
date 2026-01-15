# Build and Runtime stage
FROM alpine:3.19

LABEL maintainer="CyberPot Team"
LABEL description="Mailoney Honeypot"

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    git \
    libcap \
    python3

# Install mailoney from git
WORKDIR /opt/mailoney
RUN git clone https://github.com/t3chn0m4g3/mailoney . && \
    git checkout 06e54bd410e0044d26d8462321f1b2811318db0b

# Setup user, groups and configs
RUN addgroup -g 2000 mailoney && \
    adduser -S -H -u 2000 -D -g 2000 mailoney && \
    chown -R mailoney:mailoney /opt/mailoney && \
    setcap cap_net_bind_service=+ep $(readlink -f $(type -P python3)) && \
    # Clean up
    rm -rf /root/* /var/cache/apk/* .git

# Start mailoney
STOPSIGNAL SIGINT
USER mailoney:mailoney
WORKDIR /opt/mailoney/

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
    CMD nc -z localhost 25 || exit 1

ENTRYPOINT ["python3", "mailoney.py"]
CMD ["-i", "0.0.0.0", "-p", "25", "-t", "schizo_open_relay"]