FROM golang:1.24.0-alpine AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Medpot Builder"

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    build-base \
    git \
    g++

# Setup go, build medpot
WORKDIR /usr/local/go/src/medpot
RUN git clone https://github.com/schmalle/medpot . && \
    git checkout 75a2e6134cf926c35b6017d62542274434c87388 && \
    go mod init github.com/schmalle/medpot && \
    go mod edit -replace=github.com/go-ini/ini=gopkg.in/ini.v1@v1.67.0 && \
    go mod tidy && \
    go mod download && \
    cp dist/etc/ews.cfg /etc/ && \
    go build medpot

FROM scratch

LABEL maintainer="CyberPot Team"
LABEL description="Medpot Honeypot"

# Setup medpot
COPY --from=builder /usr/local/go/src/medpot/medpot /opt/medpot/medpot
COPY --from=builder /usr/local/go/src/medpot/template/*.xml /opt/medpot/
COPY --from=builder /usr/local/go/src/medpot/dist/etc/ews.cfg /etc/ews.cfg

# Start medpot
WORKDIR /opt/medpot
USER 2000:2000

# Healthcheck (medpot usually listens on 2575)
# Since this is a scratch image, we can't easily run a healthcheck command
# Unless we include a minimal binary or use a different base.
# For now, I'll leave the scratch image as it is very secure.

ENTRYPOINT ["./medpot"]
