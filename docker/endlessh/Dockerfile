# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Endlessh Builder"

# Install packages
RUN apk -U add --no-cache \
    build-base \
    git

WORKDIR /opt/endlessh
RUN git clone https://github.com/skeeto/endlessh . && \
    git checkout dfe44eb2c5b6fc3c48a39ed826fe0e4459cdf6ef && \
    make

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Endlessh SSH Tarpit"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add libcap

COPY --from=builder /opt/endlessh/endlessh /opt/endlessh/endlessh
COPY dist/endlessh.conf /opt/endlessh/endlessh.conf

RUN setcap 'cap_net_bind_service=+ep' /opt/endlessh/endlessh

WORKDIR /opt/endlessh/
USER 2000:2000

# Start endlessh
STOPSIGNAL SIGINT

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --retries=3 \
    CMD nc -z localhost 2222 || exit 1

ENTRYPOINT ["./endlessh"]
CMD ["-f", "endlessh.conf"]
