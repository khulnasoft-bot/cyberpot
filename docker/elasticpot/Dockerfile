# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Elasticpot Builder"

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
RUN git clone https://gitlab.com/bontchev/elasticpot.git/ /opt/elasticpot && \
	cd /opt/elasticpot && \
	git checkout d12649730d819bd78ea622361b6c65120173ad45

WORKDIR /opt/elasticpot
RUN cp /root/dist/requirements.txt . && \
	pip3 install --break-system-packages pyinstaller && \
	pip3 install --break-system-packages -r requirements.txt && \
	pyinstaller elasticpot.py \
	--hidden-import output_plugins \
	--hidden-import output_plugins.jsonlog

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Elasticpot Honeypot"

RUN apk --no-cache -U upgrade && \
	apk --no-cache add python3

COPY --from=builder /opt/elasticpot/dist/elasticpot /opt/elasticpot/elasticpot
COPY --from=builder /opt/elasticpot/responses/ /opt/elasticpot/responses/
COPY dist/honeypot.cfg /opt/elasticpot/etc/honeypot.cfg

WORKDIR /opt/elasticpot
USER 2000:2000

# Start elasticpot
STOPSIGNAL SIGINT

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
	CMD nc -z localhost 9200 || exit 1

ENTRYPOINT ["./elasticpot"]
