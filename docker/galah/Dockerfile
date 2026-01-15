# Build stage
FROM golang:1.24.0-alpine AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Galah Builder"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add build-base git

WORKDIR /opt/galah
RUN git clone https://github.com/t3chn0m4g3/galah . && \
    git checkout d4739ec5abaed83c5367716a77908be548d3d003

ENV CGO_ENABLED=1
RUN go mod download && \
    go build -o galah ./cmd/galah

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Galah Honeypot"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add openssl

COPY --from=builder /opt/galah /opt/galah

WORKDIR /opt/galah
USER 2000:2000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD nc -z localhost 8080 || exit 1

ENTRYPOINT ["./entrypoint.sh"]
