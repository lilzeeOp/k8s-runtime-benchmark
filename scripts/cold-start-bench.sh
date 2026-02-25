#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "  Cold Start Benchmark: Go vs Django"
echo "============================================"
echo ""

# Deploy and measure Go
echo "=== Go App Cold Start ==="
GO_START=$(date +%s%N)
kubectl apply -f "$PROJECT_DIR/k8s/go-app/" > /dev/null 2>&1
kubectl rollout status deployment/go-bench --timeout=120s 2>/dev/null
GO_END=$(date +%s%N)
GO_MS=$(( (GO_END - GO_START) / 1000000 ))
echo "Go pods ready in: ${GO_MS}ms"

# Wait for health endpoint
GO_HEALTH_START=$(date +%s%N)
until curl -sf http://localhost:30080/health > /dev/null 2>&1; do sleep 0.1; done
GO_HEALTH_END=$(date +%s%N)
GO_HEALTH_MS=$(( (GO_HEALTH_END - GO_HEALTH_START) / 1000000 ))
echo "Go health responding in: ${GO_HEALTH_MS}ms after rollout"
echo ""

# Deploy and measure Django
echo "=== Django App Cold Start ==="
DJ_START=$(date +%s%N)
kubectl apply -f "$PROJECT_DIR/k8s/django-app/" > /dev/null 2>&1
kubectl rollout status deployment/django-bench --timeout=120s 2>/dev/null
DJ_END=$(date +%s%N)
DJ_MS=$(( (DJ_END - DJ_START) / 1000000 ))
echo "Django pods ready in: ${DJ_MS}ms"

DJ_HEALTH_START=$(date +%s%N)
until curl -sf http://localhost:30081/health > /dev/null 2>&1; do sleep 0.1; done
DJ_HEALTH_END=$(date +%s%N)
DJ_HEALTH_MS=$(( (DJ_HEALTH_END - DJ_HEALTH_START) / 1000000 ))
echo "Django health responding in: ${DJ_HEALTH_MS}ms after rollout"
echo ""

# Measure image sizes
echo "=== Image Sizes ==="
GO_SIZE=$(docker image inspect go-bench:v1 --format='{{.Size}}' 2>/dev/null)
DJ_SIZE=$(docker image inspect django-bench:v1 --format='{{.Size}}' 2>/dev/null)
GO_SIZE_MB=$(echo "scale=1; $GO_SIZE / 1048576" | bc)
DJ_SIZE_MB=$(echo "scale=1; $DJ_SIZE / 1048576" | bc)
echo "Go image:     ${GO_SIZE_MB} MB"
echo "Django image:  ${DJ_SIZE_MB} MB"
echo ""

# Measure memory per pod
echo "=== Memory Usage (waiting for metrics...) ==="
sleep 15
kubectl top pods -l "app in (go-bench, django-bench)" 2>/dev/null || echo "Metrics not yet available"
echo ""

echo "============================================"
echo "  Summary"
echo "============================================"
echo "Cold start (rollout):  Go=${GO_MS}ms  Django=${DJ_MS}ms"
echo "Health endpoint ready: Go=${GO_HEALTH_MS}ms  Django=${DJ_HEALTH_MS}ms"
echo "Image size:            Go=${GO_SIZE_MB}MB  Django=${DJ_SIZE_MB}MB"
SPEEDUP=$(echo "scale=1; $DJ_MS / $GO_MS" | bc 2>/dev/null || echo "N/A")
echo "Go cold start is ${SPEEDUP}x faster"
echo "============================================"
