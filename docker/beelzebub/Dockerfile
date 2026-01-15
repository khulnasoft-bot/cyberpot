FROM golang:1.23.0-alpine AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Beelzebub Builder"

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux

# Install packages
RUN apk -U add git

WORKDIR /root/beelzebub

# Build beelzebub
RUN git clone https://github.com/t3chn0m4g3/beelzebub . && \
    git checkout 0b9aba53ec1671f669d22782758142a1d411b858

RUN go mod download
RUN go build -o main .
RUN sed -i "s#logsPath: ./log#logsPath: ./configurations/log/beelzebub.json#g" configurations/beelzebub.yaml
RUN sed -i 's/passwordRegex: "^(root|qwerty|Smoker666|123456|jenkins|minecraft|sinus|alex|postgres|Ly123456)$"/passwordRegex: ".*"/g' configurations/services/ssh-22.yaml

FROM scratch

LABEL maintainer="CyberPot Team"
LABEL description="Beelzebub Honeypot"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /root/beelzebub/main /opt/beelzebub/
COPY --from=builder /root/beelzebub/configurations /opt/beelzebub/configurations

# Start beelzebub
WORKDIR /opt/beelzebub
USER 2000:2000

# Healthcheck
# Again, scratch image makes healthcheck tricky without extra binaries.
# But for interactive honeypots, basic TCP check is often enough if we had a shell.

ENTRYPOINT ["./main"]
