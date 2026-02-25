#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Building Go app images ==="
echo "Building go-bench:v1..."
docker build -t go-bench:v1 --build-arg APP_VERSION=v1 "$PROJECT_DIR/go-app"

echo "Building go-bench:v2..."
docker build -t go-bench:v2 --build-arg APP_VERSION=v2 "$PROJECT_DIR/go-app"

echo ""
echo "=== Building Django app images ==="
echo "Building django-bench:v1..."
docker build -t django-bench:v1 --build-arg APP_VERSION=v1 "$PROJECT_DIR/django-app"

echo "Building django-bench:v2..."
docker build -t django-bench:v2 --build-arg APP_VERSION=v2 "$PROJECT_DIR/django-app"

echo ""
echo "=== Building Rust app images ==="
echo "Building rust-bench:v1..."
docker build -t rust-bench:v1 --build-arg APP_VERSION=v1 "$PROJECT_DIR/rust-app"

echo "Building rust-bench:v2..."
docker build -t rust-bench:v2 --build-arg APP_VERSION=v2 "$PROJECT_DIR/rust-app"

echo ""
echo "=== Build complete ==="
docker images | grep -E "go-bench|django-bench|rust-bench"
