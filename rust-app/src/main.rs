use axum::{extract::Query, http::StatusCode, response::Json, routing::get, Router};
use serde::{Deserialize, Serialize};
use std::time::Instant;

const VERSION: &str = env!("APP_VERSION");

#[tokio::main]
async fn main() {
    let boot_start = Instant::now();

    let app = Router::new()
        .route("/health", get(health))
        .route("/compute", get(compute))
        .route("/payload", get(payload));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    let startup_us = boot_start.elapsed().as_micros();
    println!("rust-bench {} listening on :8080 (startup: {}us / {:.3}ms)", VERSION, startup_us, startup_us as f64 / 1000.0);
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "app": "rust-bench",
        "version": VERSION
    }))
}

#[derive(Deserialize)]
struct ComputeParams {
    n: Option<u64>,
}

async fn compute(Query(params): Query<ComputeParams>) -> Result<Json<serde_json::Value>, StatusCode> {
    let n = params.n.unwrap_or(10000);
    if n < 2 {
        return Err(StatusCode::BAD_REQUEST);
    }

    let start = Instant::now();
    let count = count_primes(n);
    let duration_ms = start.elapsed().as_secs_f64() * 1000.0;

    Ok(Json(serde_json::json!({
        "app": "rust-bench",
        "version": VERSION,
        "n": n,
        "prime_count": count,
        "duration_ms": duration_ms
    })))
}

#[derive(Deserialize)]
struct PayloadParams {
    size: Option<usize>,
}

#[derive(Serialize)]
struct Item {
    id: usize,
    name: String,
    value: usize,
    active: bool,
}

async fn payload(Query(params): Query<PayloadParams>) -> Result<Json<serde_json::Value>, StatusCode> {
    let size = params.size.unwrap_or(100);
    if size < 1 {
        return Err(StatusCode::BAD_REQUEST);
    }

    let start = Instant::now();
    let items: Vec<Item> = (0..size)
        .map(|i| Item {
            id: i,
            name: format!("item-{}", i),
            value: i * 42,
            active: i % 2 == 0,
        })
        .collect();
    let duration_ms = start.elapsed().as_secs_f64() * 1000.0;

    Ok(Json(serde_json::json!({
        "app": "rust-bench",
        "version": VERSION,
        "item_count": size,
        "duration_ms": duration_ms,
        "items": items
    })))
}

fn count_primes(n: u64) -> u64 {
    let mut count = 0u64;
    for i in 2..=n {
        if is_prime(i) {
            count += 1;
        }
    }
    count
}

fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }
    let mut i = 3u64;
    while i * i <= n {
        if n % i == 0 {
            return false;
        }
        i += 2;
    }
    true
}
