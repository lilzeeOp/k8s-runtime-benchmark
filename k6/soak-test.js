import http from "k6/http";
import { check, sleep } from "k6";

const TARGET_URL = __ENV.TARGET_URL || "http://localhost:30080";
const PRIME_N = __ENV.PRIME_N || "10000";

export const options = {
  stages: [
    { duration: "30s", target: 30 },
    { duration: "9m", target: 30 },
    { duration: "30s", target: 0 },
  ],
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<5000"],
  },
};

export default function () {
  if (Math.random() < 0.8) {
    const res = http.get(`${TARGET_URL}/compute?n=${PRIME_N}`);
    check(res, {
      "compute status 200": (r) => r.status === 200,
    });
  } else {
    const res = http.get(`${TARGET_URL}/health`);
    check(res, {
      "health status 200": (r) => r.status === 200,
    });
  }

  sleep(0.3);
}
