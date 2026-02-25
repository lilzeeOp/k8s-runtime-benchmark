FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY main.go ./

ARG APP_VERSION=v1

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X main.version=${APP_VERSION}" -o /go-bench .

FROM alpine:3.19

COPY --from=builder /go-bench /go-bench

EXPOSE 8080

CMD ["/go-bench"]
