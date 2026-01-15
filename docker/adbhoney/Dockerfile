# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="ADBHoney Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
	apk --no-cache -U add \
	build-base \
	git \
	py3-pip \
	python3

COPY dist/ /root/dist/

# Install adbhoney from git
WORKDIR /opt/adbhoney
RUN git clone https://github.com/t3chn0m4g3/ADBHoney . && \
	git checkout 42a73cd8a82ddd4d137de70ac37b1a8b2e3e0119 && \
	cp /root/dist/adbhoney.cfg . && \
	sed -i 's/dst_ip/dest_ip/' adbhoney/core.py && \
	sed -i 's/dst_port/dest_port/' adbhoney/core.py && \
	pip3 install --break-system-packages pyinstaller && \
	pyinstaller adbhoney.spec

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="ADBHoney Honeypot"

RUN apk --no-cache -U upgrade && \
	apk --no-cache add python3

COPY --from=builder /opt/adbhoney/dist/adbhoney/ /opt/adbhoney/

# Set workdir and start adbhoney
STOPSIGNAL SIGINT
USER 2000:2000
WORKDIR /opt/adbhoney/

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
	CMD nc -z localhost 5555 || exit 1

ENTRYPOINT ["./adbhoney"]
