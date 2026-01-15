# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Ipphoney Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
	apk --no-cache -U add \
	build-base \
	ca-certificates \
	git \
	libffi-dev \
	openssl-dev \
	postgresql-dev \
	py3-pip \
	python3 \
	python3-dev

COPY dist/ /root/dist/

WORKDIR /opt
RUN git clone https://gitlab.com/bontchev/ipphoney.git/ /opt/ipphoney && \
	cd /opt/ipphoney && \
	git checkout 9da0a9e7f9d839e4522f56b3bb2b790d87d65457

WORKDIR /opt/ipphoney
RUN cp /root/dist/requirements.txt . && \
	pip3 install --break-system-packages pyinstaller && \
	pip3 install --break-system-packages -r requirements.txt && \
	pyinstaller ipphoney.py \
	--hidden-import output_plugins \
	--hidden-import output_plugins.jsonlog

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Ipphoney Honeypot"

RUN apk --no-cache -U upgrade && \
	apk --no-cache add python3

COPY --from=builder /opt/ipphoney/dist/ /opt/
COPY --from=builder /opt/ipphoney/responses/ /opt/ipphoney/responses/
COPY dist/honeypot.cfg /opt/ipphoney/etc/

WORKDIR /opt/ipphoney
USER 2000:2000

# Start ipphoney
STOPSIGNAL SIGINT

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
	CMD nc -z localhost 631 || exit 1

ENTRYPOINT ["./ipphoney"]
