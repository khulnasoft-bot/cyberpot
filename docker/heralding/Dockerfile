# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Heralding Builder"

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

COPY dist/ /root/dist/

WORKDIR /opt/heralding
RUN git clone https://github.com/johnnykv/heralding . && \
	git checkout ac12724ab38c4e2fe78f07d1bc35e6e586ba69c0 && \
	cp /root/dist/requirements.txt . && \
	pip3 install --break-system-packages --no-cache-dir --upgrade pip && \
	pip3 install --break-system-packages --no-cache-dir -r requirements.txt && \
	pip3 install --break-system-packages --no-cache-dir .

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Heralding Honeypot"

# Install runtime packages
RUN apk --no-cache -U upgrade && \
	apk --no-cache add \
	libcap \
	python3 \
	py3-pyzmq \
	py3-requests \
	py3-yaml \
	py3-psycopg2 \
	py3-cryptography

# Setup user and app
RUN addgroup -g 2000 heralding && \
	adduser -S -H -u 2000 -D -g 2000 heralding && \
	mkdir -p /var/log/heralding/ /etc/heralding

COPY --from=builder /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /usr/bin/heralding /usr/bin/heralding
COPY dist/heralding.yml /etc/heralding/

RUN setcap cap_net_bind_service=+ep $(readlink -f $(type -P python3)) && \
	chown -R heralding:heralding /var/log/heralding

WORKDIR /var/log/heralding
USER heralding:heralding

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
	CMD pgrep heralding || exit 1

ENTRYPOINT ["heralding"]
CMD ["-c", "/etc/heralding/heralding.yml", "-l", "/var/log/heralding/heralding.log"]
