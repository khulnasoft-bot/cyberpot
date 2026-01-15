# Stage 1: Build Snare
FROM python:3.12-alpine3.21 AS builder

RUN apk --no-cache add \
    build-base \
    git \
    linux-headers

# Setup Snare
COPY dist/ /root/dist/
RUN git clone https://github.com/mushorg/snare /opt/snare && \
    cd /opt/snare/ && \
    git checkout 08c69b7165354ea2040b6170c37d92ff3c304f96 && \
    cp /root/dist/requirements.txt . && \
    pip3 install --break-system-packages --no-cache-dir -r requirements.txt && \
    python3 setup.py install

# Stage 2: Final image
FROM python:3.12-alpine3.21
LABEL org.opencontainers.image.authors="KhulnaSoft" \
    org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot" \
    org.opencontainers.image.title="CyberPot Snare" \
    org.opencontainers.image.description="Snare (frontend for Tanner) for CyberPot"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add curl && \
    # Setup user
    addgroup -g 2000 snare && \
    adduser -S -H -s /bin/ash -u 2000 -D -g 2000 snare

# Copy installed packages and binaries
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/snare /usr/local/bin/

# Setup snare pages
RUN mkdir -p /opt/snare/pages
COPY dist/pages/ /opt/snare/pages/

RUN chown -R snare:snare /opt/snare && \
    # Clean up
    rm -rf /root/* /tmp/* /var/tmp/* /var/cache/apk/*

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD curl -f http://localhost:80/ || exit 1

# Start snare
USER snare:snare
CMD ["snare", "--tanner", "tanner", "--debug", "true", "--auto-update", "false", "--host-ip", "0.0.0.0", "--port", "80", "--page-dir", "1"]