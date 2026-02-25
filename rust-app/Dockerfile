FROM rust:1.77-alpine AS builder

RUN apk add --no-cache musl-dev

WORKDIR /app

COPY Cargo.toml Cargo.lock* ./
COPY src ./src

ARG APP_VERSION=v1

RUN RUSTFLAGS="-C target-feature=-crt-static" \
    APP_VERSION=${APP_VERSION} \
    cargo build --release

FROM alpine:3.19

RUN apk add --no-cache libgcc

COPY --from=builder /app/target/release/rust-bench /rust-bench

EXPOSE 8080

CMD ["/rust-bench"]
