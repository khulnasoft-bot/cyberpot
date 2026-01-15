# Build stage
FROM golang:1.24.0-alpine AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Go-pot Builder"

RUN apk --no-cache add git

WORKDIR /opt/go-pot
RUN git clone https://github.com/ryanolee/go-pot . && \
    git checkout v1.0.0

RUN CGO_ENABLED=0 GOOS=linux go build -o go-pot

# Runtime stage
FROM scratch

LABEL maintainer="CyberPot Team"
LABEL description="Go-pot Honeypot"

COPY --from=builder /opt/go-pot/go-pot /opt/go-pot/go-pot
COPY dist/config.yml /opt/go-pot/config.yml

WORKDIR /opt/go-pot
USER 2000:2000

# Start go-pot
STOPSIGNAL SIGINT

ENTRYPOINT ["./go-pot"]
CMD ["start", "--host", "0.0.0.0", "--config-file", "config.yml"]