import http from "k6/http";
import { check, sleep } from "k6";

const TARGET_URL = __ENV.TARGET_URL || "http://localhost:30080";
const PRIME_N = __ENV.PRIME_N || "10000";

export const options = {
  stages: [
    { duration: "10s", target: 5 },
    { duration: "5s", target: 100 },
    { duration: "1m", target: 100 },
    { duration: "30s", target: 50 },
    { duration: "30s", target: 0 },
  ],
  thresholds: {
    http_req_failed: ["rate<0.10"],
    http_req_duration: ["p(95)<10000"],
  },
};

export default function () {
  if (Math.random() < 0.8) {
    const res = http.get(`${TARGET_URL}/compute?n=${PRIME_N}`);
    check(res, {
      "compute status 200": (r) => r.status === 200,
      "compute has prime_count": (r) => {
        const body = JSON.parse(r.body);
        return body.prime_count !== undefined;
      },
    });
  } else {
    const res = http.get(`${TARGET_URL}/health`);
    check(res, {
      "health status 200": (r) => r.status === 200,
      "health status ok": (r) => {
        const body = JSON.parse(r.body);
        return body.status === "ok";
      },
    });
  }

  sleep(0.3);
}
