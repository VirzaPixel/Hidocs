import { Rate, Trend, Counter } from 'k6/metrics';

// Environment variables with sensible defaults (Using 127.0.0.1 for reliable IPv4 binding on Windows)
export const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8080';
export const API_PREFIX = `${BASE_URL}/api/v1`;

export const ADMIN_EMAIL = __ENV.ADMIN_EMAIL || 'admin@hidocs.id';
export const ADMIN_PASSWORD = __ENV.ADMIN_PASSWORD || 'admin123';

export const USER_EMAIL = __ENV.USER_EMAIL || 'admin@hidocs.id';
export const USER_PASSWORD = __ENV.USER_PASSWORD || 'admin123';

export const SEEDED_FORM_SLUG = __ENV.FORM_SLUG || 'perhatikan-ilustrasi-berikut-berdasarkan-jenisnya';
export const SEEDED_FORM_ID = __ENV.FORM_ID || '346ed6d4-94e4-4012-924d-1ba66e048a9f';

// Custom Metrics for deep performance tracking
export const errorRate = new Rate('custom_error_rate');
export const studentExamLatency = new Trend('student_exam_latency_ms', true);
export const autosaveLatency = new Trend('autosave_latency_ms', true);
export const telemetryLatency = new Trend('telemetry_latency_ms', true);
export const submissionLatency = new Trend('submission_latency_ms', true);
export const creatorCrudLatency = new Trend('creator_crud_latency_ms', true);
export const liveMonitoringLatency = new Trend('live_monitoring_latency_ms', true);
export const adminMetricsLatency = new Trend('admin_metrics_latency_ms', true);
export const successfulSubmissions = new Counter('successful_submissions');
export const failedSubmissions = new Counter('failed_submissions');

// Helper to construct standard headers
export function getHeaders(token = null, extraHeaders = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...extraHeaders,
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}
