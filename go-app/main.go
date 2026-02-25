package main

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"time"
)

var version = "v1"

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/compute", computeHandler)
	http.HandleFunc("/payload", payloadHandler)

	fmt.Printf("go-bench %s listening on :8080\n", version)
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Printf("server error: %v\n", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "ok",
		"app":     "go-bench",
		"version": version,
	})
}

func computeHandler(w http.ResponseWriter, r *http.Request) {
	nStr := r.URL.Query().Get("n")
	if nStr == "" {
		nStr = "10000"
	}

	n, err := strconv.Atoi(nStr)
	if err != nil || n < 2 {
		http.Error(w, `{"error":"invalid parameter n"}`, http.StatusBadRequest)
		return
	}

	start := time.Now()
	count := countPrimes(n)
	duration := time.Since(start)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"app":         "go-bench",
		"version":     version,
		"n":           n,
		"prime_count": count,
		"duration_ms": float64(duration.Microseconds()) / 1000.0,
	})
}

func payloadHandler(w http.ResponseWriter, r *http.Request) {
	sizeStr := r.URL.Query().Get("size")
	if sizeStr == "" {
		sizeStr = "100"
	}

	size, err := strconv.Atoi(sizeStr)
	if err != nil || size < 1 {
		http.Error(w, `{"error":"invalid parameter size"}`, http.StatusBadRequest)
		return
	}

	start := time.Now()
	items := make([]map[string]interface{}, size)
	for i := 0; i < size; i++ {
		items[i] = map[string]interface{}{
			"id":    i,
			"name":  fmt.Sprintf("item-%d", i),
			"value": i * 42,
			"active": i%2 == 0,
		}
	}
	duration := time.Since(start)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"app":         "go-bench",
		"version":     version,
		"item_count":  size,
		"duration_ms": float64(duration.Microseconds()) / 1000.0,
		"items":       items,
	})
}

func countPrimes(n int) int {
	count := 0
	for i := 2; i <= n; i++ {
		if isPrime(i) {
			count++
		}
	}
	return count
}

func isPrime(n int) bool {
	if n < 2 {
		return false
	}
	if n == 2 {
		return true
	}
	if n%2 == 0 {
		return false
	}
	for i := 3; i <= int(math.Sqrt(float64(n))); i += 2 {
		if n%i == 0 {
			return false
		}
	}
	return true
}
