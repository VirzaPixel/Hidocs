import { sleep, group } from 'k6';
import { getAuthToken } from './helpers/auth.js';
import {
  healthCheckFlow,
  creatorCrudFlow,
  studentExamFlow,
  adminMonitoringFlow,
} from './helpers/workflows.js';

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.01'], // less than 1% failure
    http_req_duration: ['p(95)<350', 'p(99)<600'], // 95% of requests must complete below 350ms
    http_req_waiting: ['p(95)<300'],
    checks: ['rate>0.99'], // 99%+ checks passed
  },
};

// Setup runs once before test execution to initialize auth tokens and baseline state
export function setup() {
  const userToken = getAuthToken('user');
  const adminToken = getAuthToken('admin');

  // Pre-seed an initial form for testing public exam flow
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
  group('1. Smoke - System Health & Discovery', () => {
    healthCheckFlow();
  });

  group('2. Smoke - Creator Flow (CRUD & Monitoring)', () => {
    if (data.userToken) {
      creatorCrudFlow(data.userToken);
    }
  });

  group('3. Smoke - Student Live Exam Flow', () => {
    studentExamFlow(data.seededForm);
  });

  group('4. Smoke - Admin Metrics & Dashboard', () => {
    if (data.adminToken) {
      adminMonitoringFlow(data.adminToken);
    }
  });

  sleep(1);
}
