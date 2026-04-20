FROM alpine:3.19

RUN apk add --no-cache bash curl grep

WORKDIR /app

COPY update-dns.sh .

RUN chmod +x update-dns.sh

CMD ["./update-dns.sh"]