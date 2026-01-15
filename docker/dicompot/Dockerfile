# Build stage
FROM golang:1.23.0-alpine AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Dicompot Builder"

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux

# Install packages
RUN apk --no-cache -U add \
    build-base \
    git \
    g++

COPY dist/ /root/dist/

WORKDIR /go/src/dicompot
RUN git clone https://github.com/nsmfoo/dicompot.git . && \
    git checkout 41331194156bbb17078bcc1594f4952ac06a731e && \
    cp /root/dist/go.mod . && \
    go mod tidy && \
    go mod download && \
    go build -o dicompot server/main.go

# Runtime stage
FROM scratch

LABEL maintainer="CyberPot Team"
LABEL description="Dicompot Honeypot"

COPY --from=builder /go/src/dicompot/dicompot /opt/dicompot/dicompot
COPY --from=builder /root/dist/dcm_pts/images /opt/dicompot/images

WORKDIR /opt/dicompot
USER 2000:2000

ENTRYPOINT ["./dicompot"]
CMD ["-ip","0.0.0.0","-dir","images","-log","/var/log/dicompot/dicompot.log"]
