# HiDocs Frontend — Setup

Zip ini HANYA berisi kode yang perlu ditambahkan ke project Vite + React yang sudah kamu
buat lewat `npm create vite@latest`. Tidak ada `package.json`, `package-lock.json`, atau
file bawaan Vite lainnya — extract folder `src/` di zip ini dan **timpa** folder `src/`
project kamu, lalu taruh `tailwind.config.js` dan `postcss.config.js` di root project
(sejajar dengan `package.json`).

## 1. Install dependency yang dipakai

```bash
npm install react-router-dom axios zustand @tanstack/react-query react-hook-form @hookform/resolvers zod lucide-react katex recharts
npm install -D tailwindcss postcss autoprefixer
```

Kalau project Vite kamu belum punya `react` dan `react-dom` (harusnya sudah ada dari
`npm create vite@latest`), install juga:

```bash
npm install react react-dom
```

## 2. Font Inter (opsional tapi direkomendasikan)

Tambahkan di `index.html` (di dalam `<head>`), atau skip saja — CSS sudah fallback ke
`system-ui` kalau font ini tidak ada:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

## 3. Environment variable

Buat file `.env` di root project:

```
VITE_API_BASE_URL=http://localhost:8080/api/v1
```

Ganti sesuai alamat backend Go kamu (waktu production, ganti ke domain VPS-mu, mis.
`https://api.hidocs.id/api/v1`).

## 4. Pastikan `index.html` kamu masih standar bawaan Vite

Tidak perlu diubah — cukup punya:
```html
<div id="root"></div>
<script type="module" src="/src/main.jsx"></script>
```
(ini sudah default dari `npm create vite@latest`, jadi biasanya tidak perlu disentuh sama sekali)

## 5. Jalankan

```bash
npm run dev
```

## Yang perlu kamu tahu soal isi frontend ini

- **Struktur**: `src/lib/api.js` berisi SEMUA fungsi pemanggilan API ke backend Go,
  dikelompokkan per resource (authApi, formApi, questionApi, questionBankApi, responseApi,
  aiApi, userApi). Kalau backend nanti nambah/ubah endpoint, cukup edit file ini.
- **Auth**: token JWT disimpan di `localStorage` (key `hidocs_token`), otomatis dilampirkan
  ke tiap request lewat interceptor axios di `src/lib/apiClient.js`. Kalau dapat 401,
  otomatis logout & redirect ke `/login`.
- **Live Monitoring**: polling tiap 8 detik (bukan WebSocket, sesuai backend saat ini) —
  bisa diatur di `src/features/monitoring/LiveTab.jsx` (`POLL_INTERVAL_MS`).
- **Status "Review"**: BUKAN status asli dari backend (backend cuma punya DRAFT/ACTIVE/CLOSED
  di enum, walau `REVIEW` sudah diterima validasinya). Frontend menampilkannya sebagai
  heuristik: form berstatus DRAFT yang sudah punya minimal 1 soal ditampilkan dengan badge
  "Review". Ini murni tampilan (`displayFormStatus()` di `src/lib/utils.js`).
- **Bank Soal**: menyalin soal (copy), bukan referensi live — sudah dijelaskan di UI-nya
  langsung (modal "Simpan ke Bank Soal").
- **Belum diimplementasikan** (di luar scope yang kita sepakati): virtualisasi list untuk
  daftar super panjang (saat ini cukup mengandalkan pagination 20-25 item/halaman, yang
  sudah membatasi jumlah DOM node per waktu — jadi tetap aman untuk skala 800-1000 respons,
  hanya belum pakai react-virtual), import siswa massal (endpoint `userApi.importStudents`
  sudah ada di api.js tapi belum ada halaman UI-nya), dan pengaturan cover image/logo form
  (field-nya sudah ada di `FormSettingsPanel` tapi belum ada upload UI-nya, hanya diteruskan
  apa adanya dari data yang sudah ada).
