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
    { duration: '30s', target: 10 },   // Low baseline traffic
    { duration: '15s', target: 350 },  // Abrupt traffic spike (e.g. simultaneous exam start)
    { duration: '1m', target: 350 },   // Maintain sudden peak
    { duration: '15s', target: 10 },   // Immediate drop back to baseline
    { duration: '45s', target: 10 },   // Cooldown period to evaluate system recovery
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'], // Allow transient errors during spike, but must recover
    http_req_duration: [
      'p(95)<2000', // 95% under 2s during spike
      'p(99)<3500', // 99% under 3.5s
    ],
    http_req_waiting: ['p(95)<1800'],
    checks: ['rate>0.95'],
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

  // During a spike, 80% represents students hitting exam verify-token and autosave
  if (rand < 0.80) {
    group('Spike - Instant Student Traffic Surge', () => {
      studentExamFlow(data.seededForm);
    });
  } else if (rand < 0.95) {
    group('Spike - Creator Proctoring', () => {
      if (data.userToken) {
        creatorCrudFlow(data.userToken);
      }
    });
  } else {
    group('Spike - Admin Dashboard', () => {
      if (data.adminToken) {
        adminMonitoringFlow(data.adminToken);
      } else {
        healthCheckFlow();
      }
    });
  }

  sleep(0.05 + Math.random() * 0.2);
}
