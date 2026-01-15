# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Cowrie Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    bash \
    build-base \
    git \
    gmp-dev \
    libcap \
    libffi-dev \
    mpc1-dev \
    mpfr-dev \
    openssl-dev \
    py3-pip \
    python3 \
    python3-dev

COPY dist/ /root/dist/

# Setup cowrie
WORKDIR /home/cowrie
RUN git clone https://github.com/cowrie/cowrie && \
    cd cowrie && \
    git checkout 7b18207485dbfc218082e82c615d948924429973

WORKDIR /home/cowrie/cowrie
RUN pip3 install --break-system-packages --upgrade --no-cache-dir pip && \
    pip3 install --break-system-packages --no-cache-dir -r requirements.txt

# Setup configs
RUN cp /root/dist/cowrie.cfg /home/cowrie/cowrie/cowrie.cfg

# Production stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Cowrie Honeypot"

# Install runtime packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache add \
    bash \
    libcap \
    openssl \
    python3 \
    py3-cryptography \
    py3-twisted \
    py3-bcrypt \
    py3-pip \
    py3-service_identity

# Setup user
RUN addgroup -g 2000 cowrie && \
    adduser -S -s /bin/ash -u 2000 -D -g 2000 cowrie

# Copy built site-packages and app
COPY --from=builder /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /home/cowrie/cowrie /home/cowrie/cowrie

RUN chown cowrie:cowrie -R /home/cowrie/cowrie && \
    setcap cap_net_bind_service=+ep $(readlink -f $(type -P python3))

# Start cowrie
ENV PYTHONPATH /home/cowrie/cowrie:/home/cowrie/cowrie/src
WORKDIR /home/cowrie/cowrie
USER cowrie:cowrie

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD nc -z localhost 2222 || exit 1

CMD ["/usr/bin/twistd", "--nodaemon", "-y", "cowrie.tac", "--pidfile", "/tmp/cowrie/cowrie.pid", "cowrie"]
