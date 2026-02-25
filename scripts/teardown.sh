#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Tearing down all K8s resources ==="
kubectl delete -f "$PROJECT_DIR/k8s/go-app/" --ignore-not-found
kubectl delete -f "$PROJECT_DIR/k8s/django-app/" --ignore-not-found
kubectl delete -f "$PROJECT_DIR/k8s/rust-app/" --ignore-not-found

echo ""
echo "=== Teardown complete ==="
kubectl get pods -l "app in (go-bench, django-bench, rust-bench)" 2>/dev/null || echo "All pods removed."
