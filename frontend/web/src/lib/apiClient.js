import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1';

export const TOKEN_KEY = 'hidocs_token';
export const REFRESH_TOKEN_KEY = 'hidocs_refresh_token';
export const USER_KEY = 'hidocs_user';

// Instance terpisah TANPA interceptor, khusus dipakai memanggil /auth/refresh.
// Kalau memakai apiClient biasa, refresh yang gagal akan memicu interceptor 401
// lagi -> refresh lagi -> loop tak berujung.
const refreshClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 15000,
});

// Simpan pasangan token hasil login / verify-otp / refresh ke localStorage.
// Backend mengirim: { token (legacy), access_token, refresh_token, ... }.
export function saveTokens({ token, access_token: accessToken, refresh_token: refreshToken } = {}) {
  const access = accessToken || token;
  if (access) localStorage.setItem(TOKEN_KEY, access);
  if (refreshToken) localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  return access || null;
}

export function clearSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

// Single-flight: kalau beberapa request kena 401 bersamaan, refresh cukup 1x
// dan request lain menunggu hasil promise yang sama.
let refreshPromise = null;

export async function refreshAccessToken() {
  const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
  if (!refreshToken) return null;

  if (!refreshPromise) {
    refreshPromise = refreshClient
      .post('/auth/refresh', { refresh_token: refreshToken })
      .then((res) => saveTokens(res.data?.data))
      .catch(() => null)
      .finally(() => {
        refreshPromise = null;
      });
  }

  return refreshPromise;
}

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
  async (error) => {
    const status = error.response?.status;
    const original = error.config;
    const isAuthEndpoint = Boolean(
      original?.url && original.url.includes('/auth/')
    );

    // 401 = access token expired. Karena backend memakai pola access token
    // pendek + refresh token panjang, di sini kita coba perpanjang otomatis
    // (hit /auth/refresh sekali) lalu ulangi request yang gagal. Pengguna tidak
    // perlu login ulang selama refresh token (14 hari) masih hidup.
    if (status === 401 && original && !original._retry && !isAuthEndpoint) {
      original._retry = true;

      const newToken = await refreshAccessToken();
      if (newToken) {
        original.headers = {
          ...(original.headers || {}),
          Authorization: `Bearer ${newToken}`,
        };
        return apiClient(original);
      }

      // Refresh token juga sudah mati -> benar-benar harus login ulang.
      clearSession();
      if (!window.location.pathname.startsWith('/login')) {
        window.location.href = '/login';
      }
    } else if (status === 401 && !isAuthEndpoint && !original?._retry) {
      clearSession();
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
