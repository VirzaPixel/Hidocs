import { responseApi } from './api';

// FIX: bug nyata — backend mengembalikan URL media RELATIF (mis. "/uploads/questions/x.png"),
// disajikan langsung dari root Gin (r.Static("/uploads", ...)), BUKAN di bawah /api/v1.
// Sebelumnya <img src="/uploads/..."> di-resolve browser relatif ke origin FRONTEND
// (localhost:5173), bukan backend (localhost:8080) — makanya preview selalu gambar rusak.
// VITE_API_BASE_URL contohnya "http://localhost:8080/api/v1" -> origin backend-nya
// "http://localhost:8080" (buang suffix /api/v1 atau /api/vN apa pun).
const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1';
const BACKEND_ORIGIN = API_BASE.replace(/\/api\/v\d+\/?$/, '');

export function resolveMediaUrl(url) {
  if (!url) return url;
  if (/^https?:\/\//i.test(url) || url.startsWith('data:') || url.startsWith('blob:')) return url;
  return `${BACKEND_ORIGIN}${url.startsWith('/') ? '' : '/'}${url}`;
}

export function cn(...parts) {
  return parts.filter(Boolean).join(' ');
}

export function formatDate(dateStr) {
  if (!dateStr) return '-';
  try {
    return new Date(dateStr).toLocaleString('id-ID', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return dateStr;
  }
}

export function timeAgo(dateStr) {
  if (!dateStr) return '-';
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const sec = Math.floor(diffMs / 1000);
  if (sec < 60) return `${sec} detik lalu`;
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min} menit lalu`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr} jam lalu`;
  return `${Math.floor(hr / 24)} hari lalu`;
}

export const QUESTION_TYPES = [
  { value: 'LONG_TEXT', label: 'Esai', hasOptions: false, autoScored: false },
  { value: 'MULTIPLE_CHOICE', label: 'Pilihan Ganda', hasOptions: true, autoScored: true },
  { value: 'CHECKBOXES', label: 'Kotak Centang', hasOptions: true, autoScored: true },
  { value: 'RATING', label: 'Rating (skala 1-5)', hasOptions: false, autoScored: false },
  { value: 'YES_NO', label: 'Ya / Tidak', hasOptions: true, autoScored: true },
  { value: 'MATCHING', label: 'Menjodohkan', hasOptions: true, autoScored: true },
];

export const CONTENT_MODES = ['text', 'math', 'code'];

export function questionTypeLabel(value) {
  return QUESTION_TYPES.find((t) => t.value === value)?.label || value;
}

export function questionTypeMeta(value) {
  return QUESTION_TYPES.find((t) => t.value === value) || QUESTION_TYPES[0];
}

export const DIFFICULTY_LEVELS = [
  { value: 'EASY', label: 'Mudah' },
  { value: 'MEDIUM', label: 'Sedang' },
  { value: 'HARD', label: 'Sulit' },
];

export const FORM_STATUS_META = {
  DRAFT: { label: 'Draft', color: 'bg-text-secondary/15 text-text-secondary' },
  REVIEW: { label: 'Review', color: 'bg-warning/15 text-warning' },
  ACTIVE: { label: 'Aktif', color: 'bg-success/15 text-success' },
  CLOSED: { label: 'Ditutup', color: 'bg-danger/15 text-danger' },
};

// Status "REVIEW" adalah heuristik UI (backend cuma simpan DRAFT/ACTIVE/CLOSED):
// form berstatus DRAFT dianggap "siap direview" begitu punya minimal satu soal.
// Ini hanya untuk tampilan; tidak tersimpan di backend, dan akan kembali ke
// tampilan DRAFT polos di device/sesi lain sebelum guru menekan "Publish".
export function displayFormStatus(form) {
  if (form.status === 'DRAFT' && (form.questions?.length || 0) > 0) {
    return 'REVIEW';
  }
  return form.status;
}

export async function downloadExport(formId, formTitle) {
  const res = await responseApi.exportBlob(formId);
  const blob = res.data;
  const disposition = res.headers?.['content-disposition'] || '';
  const match = disposition.match(/filename="?([^"]+)"?/);
  const filename = match?.[1] || `${formTitle || 'hasil-ujian'}.xlsx`;

  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  window.URL.revokeObjectURL(url);
}
