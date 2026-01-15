# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Miniprint Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
	apk --no-cache -U add \
	build-base \
	git \
	python3 \
	py3-pip

WORKDIR /opt/miniprint
RUN git clone https://github.com/t3chn0m4g3/miniprint . && \
	pip3 install --break-system-packages pyinstaller && \
	pip3 install --break-system-packages -r requirements.txt && \
	pyinstaller server.py \
	--add-data "./fake-files:./fake-files" \
	--add-data "./uploads:./uploads"

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Miniprint Printer Honeypot"

RUN apk --no-cache -U upgrade && \
	apk --no-cache add python3

COPY --from=builder /opt/miniprint/dist/server /opt/miniprint/server
COPY --from=builder /opt/miniprint/fake-files/ /opt/miniprint/fake-files/
COPY --from=builder /opt/miniprint/uploads/ /opt/miniprint/uploads/

# Start miniprint
STOPSIGNAL SIGINT
USER 2000:2000
WORKDIR /opt/miniprint/

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
	CMD nc -z localhost 9100 || exit 1

ENTRYPOINT ["./server"]
CMD ["--bind", "0.0.0.0", "--log-file", "/opt/miniprint/log/miniprint.json"]
