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
    { duration: '1m', target: 50 },  // Ramp-up to 50 concurrent virtual users
    { duration: '3m', target: 50 },  // Steady state at normal peak load
    { duration: '30s', target: 0 },  // Ramp-down
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'], // error rate < 1%
    http_req_duration: [
      'p(50)<150',  // 50% under 150ms
      'p(95)<450',  // 95% under 450ms
      'p(99)<900',  // 99% under 900ms
      'avg<200',    // average response time under 200ms
    ],
    http_req_waiting: ['p(95)<400'], // TTFB under 400ms
    checks: ['rate>0.98'],
    'autosave_latency_ms': ['p(95)<250'],
    'submission_latency_ms': ['p(95)<500'],
    'live_monitoring_latency_ms': ['p(95)<400'],
  },
};

export function setup() {
  const userToken = getAuthToken('user');
  const adminToken = getAuthToken('admin');

  // Pre-seed an active exam form
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
  // Realistic workload distribution:
  // - 65% of traffic: Students taking exams (autosave, telemetry, submit)
  // - 25% of traffic: Teachers managing forms & watching live monitoring
  // - 10% of traffic: Admin inspecting metrics & system health
  const rand = Math.random();

  if (rand < 0.65) {
    group('Student Exam Session', () => {
      studentExamFlow(data.seededForm);
    });
  } else if (rand < 0.90) {
    group('Teacher / Creator Management', () => {
      if (data.userToken) {
        creatorCrudFlow(data.userToken);
      }
    });
  } else {
    group('Admin & Telemetry Monitoring', () => {
      if (data.adminToken) {
        adminMonitoringFlow(data.adminToken);
      } else {
        healthCheckFlow();
      }
    });
  }

  // Realistic user think time between actions (300ms - 1.5s)
  sleep(0.3 + Math.random() * 1.2);
}
