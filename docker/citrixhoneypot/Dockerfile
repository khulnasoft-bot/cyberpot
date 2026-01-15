FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="CitrixHoneypot Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    build-base \
    git \
    openssl \
    py3-pip \
    python3 && \
    pip3 install --break-system-packages --no-cache-dir \
    pyinstaller \
    python-json-logger

# Install CitrixHoneypot from GitHub
WORKDIR /opt/citrixhoneypot
RUN git clone https://github.com/t3chn0m4g3/CitrixHoneypot . && \
    git checkout dee32447033a0296d053e8f881bf190f9dd7ad44 && \
    mkdir -p logs ssl && \
    openssl req \
    -nodes \
    -x509 \
    -newkey rsa:2048 \
    -keyout "/opt/citrixhoneypot/ssl/key.pem" \
    -out "/opt/citrixhoneypot/ssl/cert.pem" \
    -days 365 \
    -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd' && \
    chown 2000:2000 -R ssl/

RUN pyinstaller CitrixHoneypot.py

FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="CitrixHoneypot"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add python3 # Needed for running the binary if it depends on systems libs

COPY --from=builder /opt/citrixhoneypot/dist/CitrixHoneypot/ /opt/citrixhoneypot
COPY --from=builder /opt/citrixhoneypot/ssl /opt/citrixhoneypot/ssl
COPY --from=builder /opt/citrixhoneypot/responses/ /opt/citrixhoneypot/responses

# Set workdir and start citrixhoneypot
STOPSIGNAL SIGINT
USER 2000:2000
WORKDIR /opt/citrixhoneypot/

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD nc -z localhost 443 || exit 1

ENTRYPOINT ["./CitrixHoneypot"]
