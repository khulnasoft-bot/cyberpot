# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Conpot Builder"

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache -U add \
    build-base \
    git \
    libcap \
    libffi-dev \
    libxslt-dev \
    mariadb-dev \
    python3-dev \
    py3-pip \
    wget

WORKDIR /opt
RUN git clone https://github.com/t3chn0m4g3/cpppo /opt/cpppo && \
    cd /opt/cpppo && \
    git checkout 350d5187a941e7359c53087dcb1f0e41ece5682c && \
    pip3 install --break-system-packages --no-cache-dir --upgrade pip && \
    pip3 install --break-system-packages --no-cache-dir .

RUN git clone https://github.com/mushorg/conpot /opt/conpot && \
    cd /opt/conpot/ && \
    git checkout 26c67d11b08a855a28e87abd186d959741f46c7f && \
    # Change template default ports if <1024
    sed -i 's/port="2121"/port="21"/' conpot/templates/default/ftp/ftp.xml && \
    sed -i 's/port="8800"/port="80"/' conpot/templates/default/http/http.xml && \
    sed -i 's/port="6230"/port="623"/' conpot/templates/default/ipmi/ipmi.xml && \
    sed -i 's/port="5020"/port="502"/' conpot/templates/default/modbus/modbus.xml && \
    sed -i 's/port="10201"/port="102"/' conpot/templates/default/s7comm/s7comm.xml && \
    sed -i 's/port="16100"/port="161"/' conpot/templates/default/snmp/snmp.xml && \
    sed -i 's/port="6969"/port="69"/' conpot/templates/default/tftp/tftp.xml && \
    sed -i 's/port="16100"/port="161"/' conpot/templates/IEC104/snmp/snmp.xml && \
    sed -i 's/port="6230"/port="623"/' conpot/templates/ipmi/ipmi/ipmi.xml && \
    pip3 install --break-system-packages --no-cache-dir .

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="Conpot Honeypot"

# Install runtime packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache add \
    libcap \
    libxslt \
    mariadb-connector-c \
    python3 \
    py3-cryptography \
    py3-lxml \
    py3-psutil \
    py3-requests \
    py3-pyserial \
    py3-setuptools \
    py3-snmp \
    py3-pip \
    wget

# Setup user and directories
RUN addgroup -g 2000 conpot && \
    adduser -S -s /bin/ash -u 2000 -D -g 2000 conpot && \
    mkdir -p /etc/conpot /var/log/conpot /usr/share/wireshark && \
    wget https://www.wireshark.org/download/automated/data/manuf -o /usr/share/wireshark/manuf

COPY --from=builder /usr/lib/python3.12/site-packages /usr/lib/python3.12/site-packages
COPY --from=builder /usr/bin/conpot /usr/bin/conpot

COPY dist/conpot.cfg /etc/conpot/conpot.cfg
COPY dist/templates /usr/lib/python3.12/site-packages/conpot/templates
COPY dist/cpu_check.py /

RUN setcap cap_net_bind_service=+ep $(readlink -f $(type -P python3)) && \
    chown -R conpot:conpot /var/log/conpot

# Start conpot
STOPSIGNAL SIGINT
# Conpot sometimes hangs at 100% CPU usage, if detected container will become unhealthy and restarted by cyberpotinit
HEALTHCHECK --interval=5m --timeout=30s --retries=3 CMD python3 /cpu_check.py $(pgrep -of conpot) 99
USER conpot:conpot

WORKDIR /var/log/conpot
CMD ["/usr/bin/conpot", "--mibcache", "/tmp", "--temp_dir", "/tmp", "--template", "default", "--logfile", "/var/log/conpot/conpot.log", "--config", "/etc/conpot/conpot.cfg"]
