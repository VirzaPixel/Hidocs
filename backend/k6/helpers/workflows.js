import http from 'k6/http';
import { check, sleep } from 'k6';
import {
  BASE_URL,
  API_PREFIX,
  getHeaders,
  errorRate,
  studentExamLatency,
  autosaveLatency,
  telemetryLatency,
  submissionLatency,
  creatorCrudLatency,
  liveMonitoringLatency,
  adminMetricsLatency,
  successfulSubmissions,
  failedSubmissions,
  SEEDED_FORM_SLUG,
  SEEDED_FORM_ID,
} from './config.js';
import {
  randomString,
  generateFormPayload,
  generateQuestionPayload,
  generateAutosavePayload,
  generateTelemetryPayload,
  generateSubmitPayload,
} from './payloads.js';

/**
 * Basic Healthcheck and Root Ping flow.
 */
export function healthCheckFlow() {
  const healthRes = http.get(`${BASE_URL}/health`, {
    headers: getHeaders(),
    tags: { name: 'GET /health' },
  });

  if (healthRes.status !== 200) {
    console.error(`[k6 Health Failed] URL: ${BASE_URL}/health | Status: ${healthRes.status} | Error: ${healthRes.error || 'None'} | Body: ${healthRes.body}`);
  }

  check(healthRes, {
    'Health status is 200': (r) => r.status === 200,
    'App is healthy': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.status === 'ok';
      } catch (e) {
        return false;
      }
    },
  });

  const apiRes = http.get(`${API_PREFIX}`, {
    headers: getHeaders(),
    tags: { name: 'GET /api/v1' },
  });

  check(apiRes, {
    'API v1 ping is 200': (r) => r.status === 200,
  });
}

/**
 * Creator / Teacher Workflow:
 * 1. View profile & category list
 * 2. Fetch existing forms with response counts
 * 3. Create a new Form
 * 4. Add questions to the newly created form
 * 5. Check Live Proctoring Monitoring & Analytics
 */
export function creatorCrudFlow(token) {
  const startTime = new Date();

  // 1. Get Profile
  const profileRes = http.get(`${API_PREFIX}/users/me`, {
    headers: getHeaders(token),
    tags: { name: 'GET /users/me' },
  });

  check(profileRes, {
    'Get profile 200': (r) => r.status === 200,
  });

  // 2. List Forms
  const formsRes = http.get(`${API_PREFIX}/forms`, {
    headers: getHeaders(token),
    tags: { name: 'GET /forms' },
  });

  check(formsRes, {
    'List forms 200': (r) => r.status === 200,
  });

  // 3. Create Form
  const formPayload = JSON.stringify(generateFormPayload('flow'));
  const createFormRes = http.post(`${API_PREFIX}/forms`, formPayload, {
    headers: getHeaders(token),
    tags: { name: 'POST /forms' },
  });

  let formId = null;
  let customUrl = null;

  const createFormOk = check(createFormRes, {
    'Create form 201/200': (r) => r.status === 201 || r.status === 200,
  });

  if (createFormOk) {
    try {
      const body = JSON.parse(createFormRes.body);
      formId = body.data.id;
      customUrl = body.data.custom_url;
    } catch (e) {
      // ignore
    }
  }

  const createdQuestions = [];

  // 4. Add 2 Questions to the created form
  if (formId) {
    for (let i = 1; i <= 2; i++) {
      const qPayload = JSON.stringify(generateQuestionPayload(i));
      const addQRes = http.post(`${API_PREFIX}/forms/${formId}/questions`, qPayload, {
        headers: getHeaders(token),
        tags: { name: 'POST /forms/:form_id/questions' },
      });

      if (addQRes.status === 201 || addQRes.status === 200) {
        try {
          const qBody = JSON.parse(addQRes.body);
          createdQuestions.push(qBody.data);
        } catch (e) {
          // ignore
        }
      }
    }

    // 5. Check Live Monitoring Dashboard
    const monitorStart = new Date();
    const monitorRes = http.get(`${API_PREFIX}/forms/${formId}/live-monitoring`, {
      headers: getHeaders(token),
      tags: { name: 'GET /forms/:form_id/live-monitoring' },
    });
    liveMonitoringLatency.add(new Date() - monitorStart);

    check(monitorRes, {
      'Live monitoring 200': (r) => r.status === 200,
    });
  }

  creatorCrudLatency.add(new Date() - startTime);

  return {
    formId,
    customUrl,
    questions: createdQuestions,
  };
}

/**
 * Student / Respondent Exam Flow:
 * 1. Fetch public form via short code / custom URL
 * 2. Verify token / start session
 * 3. Perform autosave on answers + flag ragu-ragu
 * 4. Send telemetry heartbeat
 * 5. Final submit form
 */
export function studentExamFlow(formInfo) {
  const startTime = new Date();
  const randStudent = `student_${randomString(5)}@exam.id`;

  let formId = formInfo ? formInfo.formId : SEEDED_FORM_ID;
  let customUrl = formInfo ? formInfo.customUrl : SEEDED_FORM_SLUG;
  let questions = formInfo && formInfo.questions ? formInfo.questions : [];

  // If no dynamic form available, fetch seeded public form
  if (!customUrl) {
    customUrl = SEEDED_FORM_SLUG;
  }

  // 1. Fetch Public Form
  const publicFormRes = http.get(`${API_PREFIX}/public/forms/${customUrl}`, {
    headers: getHeaders(),
    tags: { name: 'GET /public/forms/:short_code' },
  });

  const getFormOk = check(publicFormRes, {
    'Public form retrieved (200 OK)': (r) => r.status === 200,
  });

  if (publicFormRes.status === 200) {
    try {
      const body = JSON.parse(publicFormRes.body);
      if (body.data) {
        formId = body.data.id;
        if (body.data.questions && body.data.questions.length > 0) {
          questions = body.data.questions;
        }
      }
    } catch (e) {
      // ignore
    }
  }

  if (!formId) {
    studentExamLatency.add(new Date() - startTime);
    return;
  }

  // 2. Verify Token & Obtain / Initialize Session
  const verifyPayload = JSON.stringify({
    token: 'EXAM2026',
    respondent_email: randStudent,
  });

  const verifyRes = http.post(`${API_PREFIX}/public/forms/${formId}/verify-token`, verifyPayload, {
    headers: getHeaders(),
    tags: { name: 'POST /public/forms/:form_id/verify-token' },
  });

  let responseId = null;
  if (verifyRes.status === 200) {
    try {
      const vBody = JSON.parse(verifyRes.body);
      responseId = vBody.data ? vBody.data.response_id : null;
      if (vBody.data && vBody.data.questions && vBody.data.questions.length > 0) {
        questions = vBody.data.questions;
      }
    } catch (e) {
      // ignore
    }
  }

  // 3. Realtime Autosave & Telemetry Heartbeat (if responseId active)
  if (responseId && questions.length > 0) {
    const q = questions[0];
    const optId = q.options && q.options.length > 0 ? q.options[0].id : null;

    // Autosave Answer
    const autosaveStart = new Date();
    const autoPayload = JSON.stringify(generateAutosavePayload(q.id, optId, '', true));
    const autoRes = http.post(`${API_PREFIX}/public/responses/${responseId}/autosave`, autoPayload, {
      headers: getHeaders(),
      tags: { name: 'POST /public/responses/:response_id/autosave' },
    });
    autosaveLatency.add(new Date() - autoRes);

    check(autoRes, {
      'Autosave answer 200': (r) => r.status === 200,
    });

    // Telemetry Heartbeat
    const teleStart = new Date();
    const telePayload = JSON.stringify(generateTelemetryPayload('HEARTBEAT', 0));
    const teleRes = http.post(`${API_PREFIX}/public/responses/${responseId}/telemetry`, telePayload, {
      headers: getHeaders(),
      tags: { name: 'POST /public/responses/:response_id/telemetry' },
    });
    telemetryLatency.add(new Date() - teleStart);

    check(teleRes, {
      'Telemetry heartbeat 200': (r) => r.status === 200,
    });

    // Session State Sync
    const sessionRes = http.get(`${API_PREFIX}/public/responses/${responseId}/session`, {
      headers: getHeaders(),
      tags: { name: 'GET /public/responses/:response_id/session' },
    });

    check(sessionRes, {
      'Get session state 200': (r) => r.status === 200,
    });
  }

  // 4. Final Submission
  const answers = questions.map((q) => ({
    question_id: q.id,
    selected_option_id: q.options && q.options.length > 0 ? q.options[0].id : null,
    answer_text: '',
  }));

  const submitStart = new Date();
  const submitPayload = JSON.stringify(generateSubmitPayload(randStudent, answers));
  const submitRes = http.post(`${API_PREFIX}/forms/${formId}/submit`, submitPayload, {
    headers: getHeaders(),
    tags: { name: 'POST /forms/:form_id/submit' },
  });
  submissionLatency.add(new Date() - submitStart);

  const submitOk = check(submitRes, {
    'Submit form 200': (r) => r.status === 200,
  });

  if (submitOk) {
    successfulSubmissions.add(1);
    errorRate.add(0);
  } else {
    failedSubmissions.add(1);
    errorRate.add(1);
  }

  studentExamLatency.add(new Date() - startTime);
}

/**
 * Admin & Realtime Metrics Monitoring Flow.
 */
export function adminMonitoringFlow(adminToken) {
  if (!adminToken) return;

  const start = new Date();

  // 1. Dashboard Stats
  const statsRes = http.get(`${API_PREFIX}/admin/dashboard/stats`, {
    headers: getHeaders(adminToken),
    tags: { name: 'GET /admin/dashboard/stats' },
  });

  check(statsRes, {
    'Admin dashboard stats 200': (r) => r.status === 200,
  });

  // 2. Realtime WebSocket / Polling Metrics
  const rtRes = http.get(`${API_PREFIX}/admin/metrics/realtime`, {
    headers: getHeaders(adminToken),
    tags: { name: 'GET /admin/metrics/realtime' },
  });

  check(rtRes, {
    'Admin realtime metrics 200': (r) => r.status === 200,
  });

  // 3. System Metrics (Memory, Goroutines)
  const sysRes = http.get(`${API_PREFIX}/admin/metrics/system`, {
    headers: getHeaders(adminToken),
    tags: { name: 'GET /admin/metrics/system' },
  });

  check(sysRes, {
    'Admin system metrics 200': (r) => r.status === 200,
  });

  // 4. Traffic History
  const historyRes = http.get(`${API_PREFIX}/admin/metrics/traffic-history?duration=1h`, {
    headers: getHeaders(adminToken),
    tags: { name: 'GET /admin/metrics/traffic-history' },
  });

  check(historyRes, {
    'Traffic history 200': (r) => r.status === 200,
  });

  adminMetricsLatency.add(new Date() - start);
}
