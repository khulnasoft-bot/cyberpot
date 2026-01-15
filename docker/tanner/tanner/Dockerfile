# Stage 1: Build Tanner
FROM python:3.12-alpine3.21 AS builder

RUN apk --no-cache add \
    build-base \
    git \
    libcap \
    libffi-dev \
    openssl-dev \
    linux-headers

# Setup Tanner
COPY dist/ /root/dist/
RUN git clone https://github.com/mushorg/tanner /opt/tanner && \
    cd /opt/tanner/ && \
    git checkout 245d628f4023e5462c7035e760a6b5eed0a33fbe && \
    cp /root/dist/config.yaml /opt/tanner/tanner/data && \
    cp /root/dist/requirements.txt . && \
    pip3 install --no-cache-dir -r requirements.txt && \
    python3 setup.py install

# Stage 2: Final image
FROM python:3.12-alpine3.21
LABEL org.opencontainers.image.authors="KhulnaSoft" \
    org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot" \
    org.opencontainers.image.title="CyberPot Tanner" \
    org.opencontainers.image.description="Tanner for CyberPot Tanner Stack"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add \
    libcap \
    libffi \
    openssl \
    py3-geoip2 \
    py3-mysqlclient \
    py3-yaml && \
    # Setup Tanner environment
    mkdir -p /opt/tanner /var/log/tanner && \
    # Setup user
    addgroup -g 2000 tanner && \
    adduser -S -H -s /bin/ash -u 2000 -D -g 2000 tanner && \
    chown -R tanner:tanner /opt/tanner /var/log/tanner

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/tanner* /usr/local/bin/
# Copy tanner files
COPY --from=builder /opt/tanner /opt/tanner

RUN chown -R tanner:tanner /opt/tanner

# Clean up
RUN rm -rf /root/* /tmp/* /var/tmp/* /var/cache/apk/*

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD pgrep python3 || exit 1

# Start tanner
USER tanner:tanner
WORKDIR /opt/tanner
CMD ["tanner"]