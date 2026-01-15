# Build stage
FROM ubuntu:24.04 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Log4Pot Builder"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y \
	build-essential \
	cargo \
	git \
	libcap2 \
	libcap2-bin \
	libcurl4-gnutls-dev \
	libffi-dev \
	libssl-dev \
	python3-pip \
	python3 \
	python3-dev \
	rust-all && \
	pip3 install --no-cache-dir --break-system-packages \
	poetry==1.8.3 \
	pycurl

WORKDIR /opt/Log4Pot
RUN git clone https://github.com/thomaspatzke/Log4Pot . && \
	git checkout 5002b1fe0f82359ef32dbc3a899e8a701dc3256e && \
	sed -i 's#"type": logtype,#"reason": logtype,#g' log4pot-server.py && \
	rm poetry.lock && \
	poetry install --no-cache --without=dev

# Runtime stage
FROM ubuntu:24.04

LABEL maintainer="CyberPot Team"
LABEL description="Log4Pot Honeypot"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
	apt-get install -y \
	python3 \
	libcap2 \
	libcap2-bin \
	libcurl4t64 \
	libffi8 \
	libssl3 && \
	rm -rf /var/lib/apt/lists/*

# Setup user and directories
RUN addgroup --gid 2000 log4pot && \
	adduser --system --no-create-home --shell /bin/bash -uid 2000 --disabled-password --disabled-login -gid 2000 log4pot && \
	mkdir -p /var/log/log4pot/log /var/log/log4pot/payloads && \
	chown log4pot:log4pot -R /var/log/log4pot

COPY --from=builder /opt/Log4Pot /opt/Log4Pot
RUN chown log4pot:log4pot -R /opt/Log4Pot && \
	setcap cap_net_bind_service=+ep $(readlink -f $(which python3))

WORKDIR /opt/Log4Pot
STOPSIGNAL SIGINT
USER log4pot:log4pot

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
	CMD python3 -c "import socket; s = socket.socket(); s.connect(('localhost', 8080))" || exit 1

CMD ["/usr/bin/python3","log4pot-server.py","--port","8080","--log","/var/log/log4pot/log/log4pot.log","--payloader","--download-dir","/var/log/log4pot/payloads/","--download-timeout","15","--response","/opt/Log4Pot/responses/sap-netweaver.html"]