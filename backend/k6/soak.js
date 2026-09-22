import { sleep, group } from 'k6';
import { getAuthToken } from './helpers/auth.js';
import {
  healthCheckFlow,
  creatorCrudFlow,
  studentExamFlow,
  adminMonitoringFlow,
} from './helpers/workflows.js';

const SOAK_DURATION = __ENV.SOAK_DURATION || '15m';

export const options = {
  stages: [
    { duration: '1m', target: 40 },             // Ramp-up to 40 sustained VUs
    { duration: SOAK_DURATION, target: 40 },    // Prolonged steady load (default 15m)
    { duration: '1m', target: 0 },              // Ramp-down
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'], // Must maintain <1% failure across entire duration
    http_req_duration: [
      'p(95)<500',  // 95% under 500ms even after prolonged run
      'p(99)<1000', // 99% under 1000ms
      'avg<200',    // Average latency should not degrade over time
    ],
    http_req_waiting: ['p(95)<450'],
    checks: ['rate>0.99'],
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

  if (rand < 0.60) {
    group('Soak - Continuous Student Exam Sessions', () => {
      studentExamFlow(data.seededForm);
    });
  } else if (rand < 0.85) {
    group('Soak - Creator Forms & Proctoring', () => {
      if (data.userToken) {
        creatorCrudFlow(data.userToken);
      }
    });
  } else {
    group('Soak - Admin & Realtime Telemetry Polling', () => {
      if (data.adminToken) {
        adminMonitoringFlow(data.adminToken);
      } else {
        healthCheckFlow();
      }
    });
  }

  // Steady cadence with natural user think time
  sleep(0.5 + Math.random() * 1.0);
}
