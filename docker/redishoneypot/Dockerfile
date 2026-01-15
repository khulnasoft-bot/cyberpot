# Build stage
FROM golang:1.23.0-alpine AS builder

LABEL maintainer="CyberPot Team"
LABEL description="RedisHoneyPot Builder"

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    build-base \
    git \
    g++

COPY dist/ /root/dist/

WORKDIR /go/src/redishoneypot
RUN git clone https://github.com/cypwnpwnsocute/RedisHoneyPot . && \
    git checkout 45adc622a423d12d76392c3a54274f6cff111d58 && \
    go mod download && \
    go build -o RedisHoneyPot

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="RedisHoneyPot"

# Install runtime packages
RUN apk --no-cache -U upgrade

# Setup user
RUN addgroup -g 2000 redispot && \
    adduser -S -H -u 2000 -D -g 2000 redispot

COPY --from=builder /go/src/redishoneypot/RedisHoneyPot /opt/redishoneypot/
COPY --from=builder /root/dist/redis.conf /opt/redishoneypot/

WORKDIR /opt/redishoneypot
USER 2000:2000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD nc -z localhost 6379 || exit 1

ENTRYPOINT ["./RedisHoneyPot"]
