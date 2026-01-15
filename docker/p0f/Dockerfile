# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="p0f Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    bash \
    build-base \
    jansson-dev \
    libpcap-dev

COPY . /opt/p0f
WORKDIR /opt/p0f

RUN ./build.sh

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="p0f Passive Fingerprinter"

RUN apk --no-cache -U upgrade && \
    apk --no-cache add \
    bash \
    jansson \
    libcap \
    libpcap

# Setup user
RUN addgroup -g 2000 p0f && \
    adduser -S -s /bin/bash -u 2000 -D -g 2000 p0f

COPY --from=builder /opt/p0f/p0f /opt/p0f/p0f
COPY --from=builder /opt/p0f/p0f.fp /opt/p0f/p0f.fp

RUN setcap cap_sys_chroot,cap_setgid,cap_net_raw=+ep /opt/p0f/p0f

# Start p0f
WORKDIR /opt/p0f
USER p0f:p0f

ENTRYPOINT ["/opt/p0f/p0f"]
CMD ["-u", "p0f", "-j", "-o", "/var/log/p0f/p0f.json", "-i", "eth0"]
