import http from 'k6/http';
import { check, sleep } from 'k6';

// k6 Stress Test Configuration for 500+ Concurrent Students
export const options = {
  noConnectionReuse: false,
  stages: [
    { duration: '15s', target: 50 }, // Ramp-up to 50 Virtual Users
    { duration: '15s', target: 100 }, // Ramp-up to 100 Virtual Users
    { duration: '15s', target: 150 }, // Spike to 500 Concurrent Virtual Users
    { duration: '15s',  target: 200 }, // Hold 500 Students submitting & reading exam
    { duration: '5s', target: 0 },   // Ramp-down to 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // 95% of requests must complete under 1000ms
    http_req_failed: ['rate<0.05'],    // Error rate must be under 5%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8088/api/v1';
const FORM_IDENTIFIER = __ENV.FORM_IDENTIFIER || 'perhatikan-ilustrasi-berikut-berdasarkan-jenisnya';

const requestParams = {
  headers: {
    'Content-Type': 'application/json',
    'Connection': 'keep-alive',
  },
  timeout: '10s',
};

export default function () {
  // 1. Student opens public form / exam (GET /public/forms/:identifier)
  const getRes = http.get(`${BASE_URL}/public/forms/${FORM_IDENTIFIER}`, requestParams);

  const isGetOk = check(getRes, {
    'GET Form status is 200': (r) => r.status === 200,
    'GET Form latency < 500ms': (r) => r.timings.duration < 500,
  });

  if (!isGetOk) {
    if (__ITER === 0 || __VU === 1) {
      console.log(`[k6 DEBUG] GET Form failed with HTTP status: ${getRes.status}, body: ${getRes.body}`);
    }
    sleep(1);
    return;
  }

  const formData = getRes.json().data;
  const formId = formData.id;
  const questions = formData.questions || [];

  // Build realistic answers payload from actual form questions & options
  const answers = [];
  if (questions.length > 0) {
    for (let q of questions) {
      if (q.options && q.options.length > 0) {
        // Randomly pick an option
        const randomOpt = q.options[Math.floor(Math.random() * q.options.length)];
        answers.push({
          question_id: q.id,
          selected_option_id: randomOpt.id,
        });
      }
    }
  }

  // 2. Student waits 2-4 seconds (Simulating reading questions)
  sleep(Math.random() * 2 + 2);

  // 3. Student submits answers serentak (POST /forms/:form_id/submit)
  const studentEmail = `student_vu${__VU}_${Date.now()}_${Math.floor(Math.random() * 1000)}@school.id`;

  const payload = JSON.stringify({
    respondent_email: studentEmail,
    answers: answers,
  });

  const submitRes = http.post(`${BASE_URL}/forms/${formId}/submit`, payload, requestParams);

  check(submitRes, {
    'Submit status is 200 or 201': (r) => r.status === 200 || r.status === 201,
    'Submit latency < 800ms': (r) => r.timings.duration < 800,
  });

  sleep(1);
}
