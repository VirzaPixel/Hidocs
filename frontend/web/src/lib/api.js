import apiClient, { toFormData, AI_TIMEOUT_MS } from './apiClient';

/* ============================= AUTH ============================= */
export const authApi = {
  register: (payload) => apiClient.post('/auth/register', payload),
  verifyOtp: (payload) => apiClient.post('/auth/verify-otp', payload),
  resendOtp: (payload) => apiClient.post('/auth/resend-otp', payload),
  login: (payload) => apiClient.post('/auth/login', payload),
  // Tukar refresh token (umur 14 hari) dengan access token baru. Dipakai
  // otomatis oleh interceptor apiClient saat menerima 401.
  refresh: (refreshToken) =>
    apiClient.post('/auth/refresh', { refresh_token: refreshToken }),
  // Cabut refresh token di server. Tanpa body = logout dari semua perangkat.
  logout: (refreshToken) =>
    apiClient.post('/auth/logout', refreshToken ? { refresh_token: refreshToken } : {}),
  forgotPassword: (payload) => apiClient.post('/auth/forgot-password', payload),
  resetPassword: (payload) => apiClient.post('/auth/reset-password', payload),
};

/* ============================= USER ============================= */
export const userApi = {
  getMe: () => apiClient.get('/users/me'),
  updateMe: (payload) => apiClient.put('/users/me', payload),
  importStudents: (payload) => apiClient.post('/users/students/import', payload),
};

/* ============================= FORMS ============================= */
export const formApi = {
  list: (params) => apiClient.get('/forms', { params }),
  categories: () => apiClient.get('/forms/categories'),
  create: (payload) => apiClient.post('/forms', payload),
  getById: (formId) => apiClient.get(`/forms/${formId}`),
  update: (formId, payload) => apiClient.put(`/forms/${formId}`, payload),
  remove: (formId) => apiClient.delete(`/forms/${formId}`),
  updateSettings: (formId, payload) => apiClient.put(`/forms/${formId}/settings`, payload),

  importDocx: (file) =>
    apiClient.post('/forms/import-docx', toFormData('file', file), {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  importExcel: (file) =>
    apiClient.post('/forms/import-excel', toFormData('file', file), {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  importPdf: (file) =>
    apiClient.post('/forms/import-pdf', toFormData('file', file), {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  getQrCode: (shortCode) => apiClient.get(`/public/forms/${shortCode}/qr`),

  // Share Monitoring
  listCollaborators: (formId) => apiClient.get(`/forms/${formId}/collaborators`),
  addCollaborator: (formId, email) => apiClient.post(`/forms/${formId}/collaborators`, { email }),
  removeCollaborator: (formId, userId) =>
    apiClient.delete(`/forms/${formId}/collaborators/${userId}`),
};

/* ============================= PUBLIC EXAM ============================= */
export const publicApi = {
  getForm: (codeOrSlug) => apiClient.get(`/public/forms/${codeOrSlug}`),
  verifyToken: (formId, token, respondentEmail = '') =>
    apiClient.post(`/public/forms/${formId}/verify-token`, {
      token,
      respondent_email: respondentEmail || undefined,
    }),
  autosave: (responseId, payload) =>
    apiClient.post(`/public/responses/${responseId}/autosave`, payload),
  telemetry: (responseId, payload) =>
    apiClient.post(`/public/responses/${responseId}/telemetry`, payload),
  submit: (formId, payload) => apiClient.post(`/forms/${formId}/submit`, payload),
};

/* ============================= QUESTIONS ============================= */
export const questionApi = {
  listByForm: (formId) => apiClient.get(`/forms/${formId}/questions`),
  create: (formId, payload) => apiClient.post(`/forms/${formId}/questions`, payload),
  update: (questionId, payload) => apiClient.put(`/questions/${questionId}`, payload),
  remove: (questionId) => apiClient.delete(`/questions/${questionId}`),
  removeOption: (optionId) => apiClient.delete(`/options/${optionId}`),

  uploadImage: (file) =>
    apiClient.post('/questions/upload-image', toFormData('image', file), {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),
  uploadMedia: (file) =>
    apiClient.post('/questions/upload-media', toFormData('file', file), {
      headers: { 'Content-Type': 'multipart/form-data' },
    }),

  saveToBank: (questionId, payload) =>
    apiClient.post(`/questions/${questionId}/save-to-bank`, payload),
};

/* ============================= QUESTION BANK ============================= */
export const questionBankApi = {
  list: (params) => apiClient.get('/question-bank', { params }),
  create: (payload) => apiClient.post('/question-bank', payload),
  update: (id, payload) => apiClient.put(`/question-bank/${id}`, payload),
  remove: (id) => apiClient.delete(`/question-bank/${id}`),
  addToForm: (id, formId) => apiClient.post(`/question-bank/${id}/add-to-form`, { form_id: formId }),
};

/* ============================= RESPONSES / MONITORING ============================= */
export const responseApi = {
  liveMonitoring: (formId) => apiClient.get(`/forms/${formId}/live-monitoring`),
  restartSession: (formId, responseId, warningMessage) =>
    apiClient.post(`/forms/${formId}/responses/${responseId}/restart`, {
      warning_message: warningMessage || 'Sesi direset oleh pengawas.',
    }),
  listByForm: (formId, params) => apiClient.get(`/forms/${formId}/responses`, { params }),
  // Export butuh header Authorization (JWT), jadi TIDAK BISA dipakai sebagai <a href>
  // biasa — harus di-fetch dengan token lalu diunduh sebagai blob. Lihat
  // downloadExport() di lib/utils.js untuk pemakaiannya.
  exportBlob: (formId) => apiClient.get(`/forms/${formId}/export`, { responseType: 'blob' }),
  analytics: (formId) => apiClient.get(`/forms/${formId}/analytics`),
  getById: (responseId) => apiClient.get(`/responses/${responseId}`),
  mySubmissions: () => apiClient.get('/responses/me'),
  grade: (responseId, payload) => apiClient.put(`/responses/${responseId}/grade`, payload),
};

/* ============================= AI ============================= */
export const aiApi = {
  templatePrompt: () => apiClient.get('/ai/template-prompt'),
  generatePreview: (payload) => apiClient.post('/ai/generate-preview', payload, { timeout: AI_TIMEOUT_MS }),
  generateForm: (payload) => apiClient.post('/ai/generate-form', payload, { timeout: AI_TIMEOUT_MS }),
  gradeEssay: (payload) => apiClient.post('/ai/grade-essay', payload, { timeout: AI_TIMEOUT_MS }),
  gradeResponse: (payload) => apiClient.post('/ai/grade-response', payload, { timeout: AI_TIMEOUT_MS }),
  transcribe: (formData) =>
    apiClient.post('/ai/transcribe', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      timeout: AI_TIMEOUT_MS,
    }),
  // FIX: baru — dipakai untuk fitur "lampirkan PDF/Word sebagai materi AI".
  // Backend mengekstrak teks mentah (bukan parsing soal), lalu teks itu
  // digabung ke raw_prompt sebelum generate-preview/generate-form.
  extractMaterial: (file) =>
    apiClient.post('/ai/extract-material', toFormData('file', file), {
      headers: { 'Content-Type': 'multipart/form-data' },
      timeout: AI_TIMEOUT_MS,
    }),
};

/* ============================= ADMIN ============================= */
export const adminApi = {
  getDashboardStats: () => apiClient.get('/admin/dashboard/stats'),
  listCreators: () => apiClient.get('/admin/creators'),
  createCreator: (payload) => apiClient.post('/admin/creators', payload),
  updateCreatorStatus: (creatorId, isActive) =>
    apiClient.put(`/admin/creators/${creatorId}/status`, { is_active: isActive }),
  listAllForms: () => apiClient.get('/admin/forms'),
  deleteForm: (formId) => apiClient.delete(`/admin/forms/${formId}`),
};

/* ============================= METRICS ============================= */
export const metricsApi = {
  getRealtimeMetrics: () => apiClient.get('/admin/metrics/realtime'),
  getSystemMetrics: () => apiClient.get('/admin/metrics/system'),
  getLiveExams: () => apiClient.get('/admin/metrics/live-exams'),
  getTrafficHistory: (duration = '1h') => apiClient.get('/admin/metrics/traffic-history', { params: { duration } }),
  getFormMetrics: (formId) => apiClient.get(`/admin/metrics/forms/${formId}`),
};

/* ============================= SUPERADMIN ============================= */
export const superadminApi = {
  createAdmin: (payload) => apiClient.post('/superadmin/create-admin', payload),
  listAdmins: () => apiClient.get('/superadmin/list-admin'),
};

