# Stage 1: Build and prepare Attack Map
FROM alpine:3.20 AS builder

RUN apk --no-cache add \
  build-base \
  git \
  python3 \
  python3-dev \
  py3-pip

RUN mkdir -p /opt && \
  cd /opt/ && \
  git clone https://github.com/khulnasoft/cyberpot-attack-map -b 3.0.0 && \
  cd cyberpot-attack-map && \
  pip3 install --break-system-packages --upgrade pip && \
  pip3 install --break-system-packages -r requirements.txt

# Stage 2: Final image
FROM alpine:3.20
LABEL org.opencontainers.image.authors="KhulnaSoft" \
  org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot" \
  org.opencontainers.image.title="CyberPot Attack Map" \
  org.opencontainers.image.description="Attack Map for CyberPot ELK Stack"

RUN apk --no-cache -U upgrade && \
  apk --no-cache add \
  libcap \
  python3 \
  py3-pip \
  tzdata && \
  # Setup user
  addgroup -g 2000 map && \
  adduser -S -H -s /bin/ash -u 2000 -D -g 2000 map

# Copy from builder
COPY --from=builder /opt/cyberpot-attack-map /opt/cyberpot-attack-map
COPY --from=builder /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /usr/bin/pip3 /usr/bin/pip3

RUN setcap cap_net_bind_service=+ep $(readlink -f $(type -P python3)) && \
  chown map:map -R /opt/cyberpot-attack-map && \
  # Clean up
  rm -rf /root/* /var/cache/apk/* /opt/cyberpot-attack-map/.git

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD nc -z 127.0.0.1 64299 || exit 1

# Start CyberPot-Attack-Map
ENV TZ=UTC
STOPSIGNAL SIGINT
USER map:map
WORKDIR /opt/cyberpot-attack-map
CMD ["/bin/sh", "-c", "/usr/bin/python3 $MAP_COMMAND"]
