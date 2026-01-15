# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Wordpot Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
	apk --no-cache -U add \
	build-base \
	git \
	libcap \
	py3-pip \
	python3 \
	python3-dev

COPY dist/ /root/dist/

WORKDIR /opt/wordpot
RUN git clone https://github.com/t3chn0m4g3/wordpot . && \
	git checkout b2701cb6c7057ed2843187c0c425bb8c13845719 && \
	cp /root/dist/requirements.txt . && \
	pip3 install --no-cache-dir --break-system-packages pyinstaller && \
	pip3 install --no-cache-dir --break-system-packages -r requirements.txt && \
	pyinstaller wordpot.py \
	--hidden-import hpfeeds \
	--add-data "./wordpot/static:./wordpot/static" \
	--add-data "./wordpot/templates:./wordpot/templates" \
	--add-data "./wordpot/plugins:./wordpot/plugins" \
	--add-data "./wordpot.conf:./"

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Wordpot Honeypot"

RUN apk --no-cache -U upgrade && \
	apk --no-cache add python3

COPY --from=builder /opt/wordpot/dist/wordpot /opt/wordpot/wordpot

WORKDIR /opt/wordpot
USER 2000:2000

# Start wordpot
STOPSIGNAL SIGINT

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
	CMD nc -z localhost 80 || exit 1

ENTRYPOINT ["./wordpot"]
CMD ["--host", "0.0.0.0", "--port", "80", "--title", "Wordpress"]
