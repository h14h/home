FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git
RUN go install tildegit.org/solderpunk/molly-brown@latest

FROM alpine:3.19

COPY --from=builder /go/bin/molly-brown /usr/local/bin/molly-brown

WORKDIR /app
COPY molly.conf /app/molly.conf
COPY cert.pem /app/cert.pem
COPY key.pem /app/key.pem
COPY content/ /app/content/

EXPOSE 1965

CMD ["molly-brown", "-c", "/app/molly.conf"]
