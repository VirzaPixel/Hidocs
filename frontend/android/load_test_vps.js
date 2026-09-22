import http from 'k6/http';
import { check, sleep } from 'k6';

// Tahap 2 - VPS live test, fokus Android backend (hidocs.my.id).
// Sopan terhadap rate-limit global 500 req/menit/IP:
// 10 VU x ~0.5 rps = ~300 req/menit, aman.
export const options = {
  stages: [
    { duration: '10s', target: 5 },
    { duration: '20s', target: 10 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000'],
  },
};

const BASE = 'https://hidocs.my.id';

export default function () {
  let r = http.get(`${BASE}/health`);
  check(r, { 'health 200': (x) => x.status === 200 });
  sleep(1);

  r = http.get(`${BASE}/api/v1`);
  check(r, { 'api index 200': (x) => x.status === 200 });
  sleep(2);
}
