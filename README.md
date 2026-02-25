# k8s-runtime-benchmark

A 3-way performance benchmark of **Rust**, **Go**, and **Django** on Kubernetes — same app, same algorithm, same K8s config, different runtimes.

## Results at a Glance

| Metric | Rust | Go | Django |
|--------|------|-----|--------|
| Docker image size | **13.5 MB** | 18.6 MB | 252 MB |
| Memory per pod (idle) | **~0 Mi** | 1 Mi | 120 Mi |
| Compute 500K primes | **19.5ms** | 27.9ms | 841ms |
| Load test p95 (50 VUs) | **3.18ms** | 3.41ms | 78.95ms |
| Spike test p95 (100 VUs) | **3.77ms** | 3.27ms | 1.28s |
| Spike throughput | **228 req/s** | 228 req/s | 103 req/s |
| HPA pods needed | **2** | 2-3 | 10 (maxed) |
| Resource squeeze (50m CPU) failures | **0%** | **0%** | **96.54%** |

> Full analysis with plain English explanations: **[BENCHMARK-REPORT.md](BENCHMARK-REPORT.md)**

## What's Being Tested

Three apps that do the exact same thing — a simple HTTP server with three endpoints:

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Returns JSON health status (used by K8s probes) |
| `GET /compute?n=50000` | Counts primes up to N (CPU-intensive) |
| `GET /payload?size=1000` | Returns a JSON array of N objects (I/O-bound) |

All three use the same prime-counting algorithm. The only variable is the language runtime:

| | Rust | Go | Django |
|--|------|-----|--------|
| Framework | Axum (async) | net/http (stdlib) | Django 5.0 + Gunicorn |
| Docker base | alpine:3.19 | alpine:3.19 | python:3.12-slim |
| NodePort | localhost:30082 | localhost:30080 | localhost:30081 |

## Project Structure

```
k8s-runtime-benchmark/
├── rust-app/           # Rust/Axum HTTP server
├── go-app/             # Go stdlib HTTP server
├── django-app/         # Django + Gunicorn HTTP server
├── k8s/
│   ├── rust-app/       # Deployment, Service, HPA
│   ├── go-app/         # Deployment, Service, HPA
│   └── django-app/     # Deployment, Service, HPA
├── k6/
│   ├── load-test.js    # Gradual ramp: 0→50 VUs over 5 min
│   ├── spike-test.js   # Sudden spike: 5→100 VUs in 5 sec
│   └── soak-test.js    # Sustained: 30 VUs for 10 min
├── scripts/
│   ├── build-all.sh    # Build v1 + v2 images for all 3 apps
│   ├── deploy-all.sh   # Deploy everything to K8s
│   └── teardown.sh     # Clean up all resources
└── BENCHMARK-REPORT.md # Full results with 11 tests
```

## Prerequisites

- **Docker Desktop** with Kubernetes enabled
- **metrics-server** (required for HPA autoscaling):
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl patch deployment metrics-server -n kube-system --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},
         {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-preferred-address-types=InternalIP"}]'
  ```
- **[Grafana K6](https://k6.io/)** for load testing

## Quick Start

```bash
# 1. Build all Docker images (v1 + v2 for each app)
bash scripts/build-all.sh

# 2. Deploy to Kubernetes
bash scripts/deploy-all.sh

# 3. Verify everything is running
curl http://localhost:30082/health   # Rust
curl http://localhost:30080/health   # Go
curl http://localhost:30081/health   # Django

# 4. Run load tests
k6 run -e TARGET_URL=http://localhost:30082 -e PRIME_N=50000 k6/load-test.js   # Rust
k6 run -e TARGET_URL=http://localhost:30080 -e PRIME_N=50000 k6/load-test.js   # Go
k6 run -e TARGET_URL=http://localhost:30081 -e PRIME_N=50000 k6/load-test.js   # Django

# 5. Watch HPA autoscaling in real time
kubectl get hpa --watch

# 6. Clean up
bash scripts/teardown.sh
```

## Tests Covered

1. **Image Size & Memory Footprint** — Docker image sizes and per-pod memory usage
2. **Compute Scaling** — Response time vs workload size (1K to 500K primes)
3. **Load Test** — Steady traffic ramp to 50 VUs over 5 minutes
4. **Spike Test** — Flash sale simulation: 5 to 100 users in 5 seconds
5. **Rolling Update** — Deploy new version during live traffic (zero-downtime)
6. **Pod Kill Recovery** — Force-kill a pod, measure recovery time
7. **Soak Test** — 10 minutes sustained load, check for memory leaks
8. **Payload Test** — JSON serialization throughput (I/O-bound)
9. **Multi-App Interference** — All apps competing for node resources
10. **Resource Squeeze** — 50 millicores CPU limit (the survival test)
11. **Cloud Cost Projection** — Estimated production resource requirements

## Environment

- Docker Desktop Kubernetes v1.34.1 on Windows 11
- Grafana K6 v0.55.0
- All tests run locally — no cloud account needed

## License

MIT
