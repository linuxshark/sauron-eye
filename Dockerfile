FROM alpine:3.9

WORKDIR /app

COPY sauron-eye.sh .

RUN chmod 755 sauron-eye.sh && \
    apk add --no-cache --update-cache bash openssl tzdata coreutils curl && \
    cp /usr/share/zoneinfo/America/Santiago /etc/localtime && \
    ls