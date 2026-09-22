import { sleep, group } from 'k6';
import { getAuthToken } from './helpers/auth.js';
import {
  healthCheckFlow,
  creatorCrudFlow,
  studentExamFlow,
  adminMonitoringFlow,
} from './helpers/workflows.js';

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Below normal load
    { duration: '2m', target: 150 },  // Approaching max normal load
    { duration: '2m', target: 300 },  // High stress limit
    { duration: '2m', target: 450 },  // Extreme breaking point search
    { duration: '1m', target: 0 },    // Ramp-down & recovery
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'], // Allow up to 5% failure under extreme stress
    http_req_duration: [
      'p(95)<1500', // 95% of requests under 1.5s
      'p(99)<3000', // 99% under 3s
      'avg<800',
    ],
    http_req_waiting: ['p(95)<1200'],
    checks: ['rate>0.95'],
    'autosave_latency_ms': ['p(95)<800'],
    'submission_latency_ms': ['p(95)<1500'],
  },
};

export function setup() {
  const userToken = getAuthToken('user');
  const adminToken = getAuthToken('admin');

  let seededForm = null;
  if (userToken) {
    seededForm = creatorCrudFlow(userToken);
  }

  return {
    userToken,
    adminToken,
    seededForm,
  };
}

export default function (data) {
  const rand = Math.random();

  // Under stress, student exam submissions and autosaves dominate (75%)
  if (rand < 0.75) {
    group('High Stress - Student Exam Submissions', () => {
      studentExamFlow(data.seededForm);
    });
  } else if (rand < 0.90) {
    group('High Stress - Creator Live Monitoring', () => {
      if (data.userToken) {
        creatorCrudFlow(data.userToken);
      }
    });
  } else {
    group('High Stress - Admin Metrics', () => {
      if (data.adminToken) {
        adminMonitoringFlow(data.adminToken);
      } else {
        healthCheckFlow();
      }
    });
  }

  // Brief randomized think time
  sleep(0.1 + Math.random() * 0.5);
}
