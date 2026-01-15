# Stage 1: Build BFR and PHPox
FROM alpine:3.21 AS builder

RUN apk --no-cache add \
    build-base \
    file \
    git \
    make \
    php83 \
    php83-dev \
    re2c

# Install bfr sandbox from git
RUN git clone https://github.com/mushorg/BFR -b v1.0.0 /opt/BFR && \
    cd /opt/BFR && \
    phpize83 && \
    ./configure \
    --with-php-config=/usr/bin/php-config83 \
    --enable-bfr && \
    make && \
    make install

# Install PHP Sandbox
RUN git clone https://github.com/mushorg/phpox /opt/phpox && \
    cd /opt/phpox && \
    git checkout 55a6cbdc2c62f08eb45acffaf84f23f06a1d4703 && \
    make

# Stage 2: Final image
FROM alpine:3.21
LABEL org.opencontainers.image.authors="KhulnaSoft" \
    org.opencontainers.image.source="https://github.com/khulnasoft/cyberpot" \
    org.opencontainers.image.title="CyberPot Tanner PHPox" \
    org.opencontainers.image.description="PHP Sandbox for CyberPot Tanner Stack"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add \
    php83 \
    py3-aiohttp \
    python3

# Copy BFR extension and PHPox
COPY --from=builder /usr/lib/php83/modules/bfr.so /usr/lib/php83/modules/bfr.so
COPY --from=builder /opt/phpox /opt/phpox

RUN echo "zend_extension = /usr/lib/php83/modules/bfr.so" >> /etc/php83/php.ini && \
    # Clean up
    rm -rf /root/* /tmp/* /var/tmp/* /var/cache/apk/*

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=10 CMD pgrep python3 || exit 1

# Set workdir and start phpsandbox
USER nobody:nobody
WORKDIR /opt/phpox
CMD ["python3", "sandbox.py"]
