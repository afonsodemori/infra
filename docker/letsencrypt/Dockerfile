FROM alpine:3

RUN apk update \
  && apk add --no-cache \
    certbot \
    certbot-nginx \
    certbot-dns-cloudflare \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

COPY --chmod=0700 ./docker/letsencrypt/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
