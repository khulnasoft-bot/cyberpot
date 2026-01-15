# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Cisco ASA Honeypot Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
	apk --no-cache -U add \
	build-base \
	git \
	libffi-dev \
	openssl-dev \
	py3-pip \
	python3 \
	python3-dev

WORKDIR /opt
RUN git clone https://github.com/t3chn0m4g3/ciscoasa_honeypot /opt/ciscoasa_honeypot && \
	cd /opt/ciscoasa_honeypot && \
	git checkout 4bd2795cfa14320a87c00b7159fa3b7d6a8ba254 && \
	sed -i "s/git+git/git+https/g" requirements.txt && \
	pip3 install --break-system-packages pyinstaller && \
	pip3 install --break-system-packages --no-cache-dir -r requirements.txt && \
	pyinstaller asa_server.py --add-data "./asa:./asa"

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Cisco ASA Honeypot"

RUN apk --no-cache -U upgrade && \
	apk --no-cache add python3

COPY --from=builder /opt/ciscoasa_honeypot/dist/asa_server /opt/asa_server

WORKDIR /opt/asa_server
USER 2000:2000

# Start ciscoasa
STOPSIGNAL SIGINT

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
	CMD nc -z localhost 8443 || exit 1

ENTRYPOINT ["./asa_server"]
CMD ["--ike-port", "5000", "--enable_ssl", "--port", "8443", "--verbose"]
