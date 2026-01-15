# Build stage
FROM golang:1.24.0-alpine AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Glutton Builder"

COPY dist/ /root/dist/

# Setup apk
RUN apk --no-cache -U upgrade && \
	apk -U --no-cache add \
	make \
	git \
	g++ \
	iptables-dev \
	libpcap-dev

WORKDIR /opt/glutton
RUN git clone https://github.com/mushorg/glutton . && \
	git checkout b3b5944b79893ccb1da19e112571674841bbe124 && \
	cp /root/dist/system.go . && \
	make build && \
	cp /root/dist/*.yaml /opt/glutton/config/

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Glutton Honeypot"

RUN apk -U --no-cache upgrade && \
	apk -U --no-cache add \
	iptables \
	libcap \
	libpcap-dev

COPY --from=builder /opt/glutton/bin /opt/glutton/bin
COPY --from=builder /opt/glutton/config /opt/glutton/config

RUN setcap cap_net_admin,cap_net_raw=+ep /opt/glutton/bin/server && \
	setcap cap_net_admin,cap_net_raw=+ep /sbin/xtables-nft-multi && \
	mkdir -p /var/log/glutton /opt/glutton/payloads

# Start glutton
WORKDIR /opt/glutton
USER 2000:2000

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
	CMD nc -z localhost 5000 || exit 1

ENTRYPOINT ["bin/server"]
CMD ["-d", "true", "-i", "eth0", "-l", "/var/log/glutton/glutton.log"]
