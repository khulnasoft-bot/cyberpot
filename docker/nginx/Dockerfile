# Build stage
FROM alpine:3.20.3 AS builder

LABEL maintainer="CyberPot Team"
LABEL description="Nginx Static Assets Preparer"

COPY dist/ /root/dist/

WORKDIR /var/lib/nginx/html
RUN mkdir -p esvue cyberchef && \
    cp -R /root/dist/html/* ./ && \
    cd esvue && \
    tar xvfz esvue.tgz && \
    rm esvue.tgz && \
    cd ../cyberchef && \
    tar xvfz cyberchef.tgz && \
    rm cyberchef.tgz

# Runtime stage
FROM alpine:3.20.3

LABEL maintainer="CyberPot Team"
LABEL description="CyberPot Management Nginx"

# Install packages
RUN apk --no-cache -U upgrade && \
    apk --no-cache add \
    nginx \
    nginx-mod-http-brotli \
    nginx-mod-http-headers-more \
    nginx-mod-http-lua

# Copy assets and configs
COPY --from=builder /var/lib/nginx/html /var/lib/nginx/html
COPY dist/conf/nginx.conf /etc/nginx/nginx.conf
COPY dist/conf/ssl /etc/nginx/ssl
COPY dist/conf/cyberpotweb.conf /etc/nginx/conf.d/cyberpotweb.conf
COPY dist/conf/lsweb.conf /etc/nginx/conf.d/lsweb.conf

RUN chown root:www-data -R /var/lib/nginx/html && \
    chmod 755 -R /var/lib/nginx/html && \
    mkdir -p /run/nginx

# Start nginx
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
