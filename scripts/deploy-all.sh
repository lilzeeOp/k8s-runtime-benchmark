#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Deploying Go app ==="
kubectl apply -f "$PROJECT_DIR/k8s/go-app/"

echo ""
echo "=== Deploying Django app ==="
kubectl apply -f "$PROJECT_DIR/k8s/django-app/"

echo ""
echo "=== Deploying Rust app ==="
kubectl apply -f "$PROJECT_DIR/k8s/rust-app/"

echo ""
echo "=== Waiting for rollouts ==="
kubectl rollout status deployment/go-bench --timeout=120s
kubectl rollout status deployment/django-bench --timeout=120s
kubectl rollout status deployment/rust-bench --timeout=120s

echo ""
echo "=== Deployment complete ==="
kubectl get pods -l "app in (go-bench, django-bench, rust-bench)"
echo ""
kubectl get svc go-bench django-bench rust-bench
echo ""
kubectl get hpa
