# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Fatt Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    git \
    py3-pip \
    python3

WORKDIR /opt/fatt
RUN git clone https://github.com/0x4D31/fatt . && \
    git checkout c29e553514281e50781f86932b82337a5ada5640 && \
    pip3 install --no-cache-dir --break-system-packages pyshark

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Fatt Fingerprint Tool"

RUN apk -U --no-cache upgrade && \
    apk -U --no-cache add \
    iptables \
    libcap \
    python3 \
    py3-libxml2 \
    py3-lxml \
    tshark

# Setup user and app
RUN addgroup -g 2000 fatt && \
    adduser -S -s /bin/ash -u 2000 -D -g 2000 fatt

COPY --from=builder /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /opt/fatt /opt/fatt

RUN chmod +x /usr/bin/dumpcap && \
    chgrp fatt /usr/bin/dumpcap && \
    setcap cap_net_raw,cap_net_admin=+eip /usr/bin/dumpcap && \
    chown fatt:fatt -R /opt/fatt

# Start fatt
STOPSIGNAL SIGINT
ENV PYTHONPATH /opt/fatt
WORKDIR /opt/fatt
USER fatt:fatt

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
    CMD pgrep python3 || exit 1

ENTRYPOINT ["python3", "fatt.py"]
CMD ["-i", "eth0", "--print_output", "--json_logging", "-o", "log/fatt.log"]
