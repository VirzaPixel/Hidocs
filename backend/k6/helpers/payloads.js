/**
 * Helper to generate random alphanumeric strings.
 */
export function randomString(length = 8) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Generates a realistic Form creation payload.
 */
export function generateFormPayload(prefix = 'exam') {
  const rand = randomString(6);
  return {
    title: `Ujian ${prefix.toUpperCase()} Performance Test ${rand}`,
    description: `Automated Load Testing Form ${rand}`,
    type: 'EXAM',
    category: 'Akademik',
    custom_url: `perf-${prefix}-${rand}`,
  };
}

/**
 * Generates a realistic Question payload.
 */
export function generateQuestionPayload(orderIndex = 1) {
  const rand = randomString(4);
  return {
    question_text: `Soal Evaluasi Kinerja Nomor ${orderIndex} - Kode ${rand}?`,
    question_type: 'MULTIPLE_CHOICE',
    points: 10,
    order_index: orderIndex,
    is_required: true,
    options: [
      { option_text: `Pilihan Jawaban A (${rand})`, is_correct: true, order_index: 1 },
      { option_text: `Pilihan Jawaban B (${rand})`, is_correct: false, order_index: 2 },
      { option_text: `Pilihan Jawaban C (${rand})`, is_correct: false, order_index: 3 },
      { option_text: `Pilihan Jawaban D (${rand})`, is_correct: false, order_index: 4 },
    ],
  };
}

/**
 * Generates an Autosave payload for student exam answering.
 */
export function generateAutosavePayload(questionId, selectedOptionId = null, answerText = '', isFlagged = false) {
  return {
    question_id: questionId,
    selected_option_id: selectedOptionId,
    answer_text: answerText,
    is_flagged: isFlagged,
  };
}

/**
 * Generates Anti-Cheat Telemetry heartbeat payload.
 */
export function generateTelemetryPayload(eventType = 'HEARTBEAT', violationCount = 0) {
  return {
    event_type: eventType,
    violation_count: violationCount,
    device_info: {
      user_agent: 'k6-performance-tester/1.0',
      screen_width: 1920,
      screen_height: 1080,
      is_fullscreen: true,
    },
  };
}

/**
 * Generates a Final Submission payload.
 */
export function generateSubmitPayload(email, answers = []) {
  return {
    respondent_email: email,
    passcode: '',
    answers: answers,
  };
}
