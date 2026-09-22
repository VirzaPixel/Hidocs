import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1';

export const TOKEN_KEY = 'hidocs_token';
export const USER_KEY = 'hidocs_user';

const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 45000,
});

// FIX: generate soal AI (Gemini) sering butuh 20-40+ detik, kadang lebih kalau
// server AI sedang sibuk. Timeout default 45s masih terlalu pendek khusus untuk
// endpoint ini — sebelumnya request AI yang SUKSES di backend (log Go: "200 |
// 29.98s") tetap ditampilkan sebagai error di frontend karena axios sudah
// membatalkan request duluan di detik ke-30.
export const AI_TIMEOUT_MS = 120000;

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Backend selalu membungkus response sebagai { success, message, data, errors }.
// Interceptor ini membongkarnya supaya kode fitur cukup pakai hasilnya langsung,
// tidak perlu `.data.data` di semua tempat.
apiClient.interceptors.response.use(
  (response) => {
    // File download (mis. export responses) bukan JSON envelope — kembalikan apa
    // adanya, jangan coba unwrap `.data.data`.
    if (response.config?.responseType === 'blob') {
      return response;
    }
    return response.data?.data;
  },
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(USER_KEY);
      if (!window.location.pathname.startsWith('/login')) {
        window.location.href = '/login';
      }
    }

    const backendMessage = error.response?.data?.message;
    const backendErrors = error.response?.data?.errors;
    const message =
      backendMessage ||
      (typeof backendErrors === 'string' ? backendErrors : null) ||
      error.message ||
      'Terjadi kesalahan. Coba lagi.';

    const wrapped = new Error(message);
    wrapped.status = error.response?.status;
    wrapped.errors = backendErrors;
    return Promise.reject(wrapped);
  }
);

// Dipakai khusus untuk request upload file (multipart), supaya Content-Type
// otomatis diisi browser (dengan boundary), bukan application/json.
export function toFormData(fileKey, file) {
  const fd = new FormData();
  fd.append(fileKey, file);
  return fd;
}

export default apiClient;
