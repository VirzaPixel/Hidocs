# Ringkasan Perbaikan Backend HiDocs

Ini BUKAN seluruh project — hanya file yang diubah atau ditambahkan. Cara pakai:
extract zip ini lalu **timpa (overwrite)** file dengan path yang sama di project asli kamu.
Struktur folder di dalam zip ini sudah sama persis dengan struktur project-mu.

## ⚠️ WAJIB DILAKUKAN SETELAH EXTRACT (satu langkah manual)

File baru `internal/infrastructure/parser/pdf_parser.go` butuh library pihak ketiga untuk
baca teks dari PDF yang sebelumnya tidak ada di project ini. `go.mod` di zip ini sudah aku
tambahkan baris `require`-nya, tapi **hash checksum di `go.sum` tidak bisa aku hasilkan** dari
sandbox ini (tidak ada akses internet). Jadi setelah extract, di root project jalankan:

```bash
go get github.com/ledongthuc/pdf@v0.0.0-20240201131950-da5b75280b06
go mod tidy
go build ./...
```

Ini akan otomatis memperbaiki `go.sum` dan menarik dependency-nya. Setelah itu pastikan
`go build ./...` sukses tanpa error sebelum deploy.

## Daftar File & Alasan Perubahan

| File | Jenis | Alasan |
|---|---|---|
| `config/config.go` | Diperbaiki | **Bug compile-breaking**: `ai_service.go` memanggil `cfg.GeminiAPIKey` & `cfg.GeminiModel` yang tidak pernah didefinisikan di struct `Config`. Ditambahkan, plus field lain yang sudah ada di `.env.example` tapi tidak pernah dibaca (`ALLOWED_ORIGINS`, `MAX_UPLOAD_MB`, `MAX_MEDIA_UPLOAD_MB`, `DB_MAX_OPEN_CONNS`, `DB_MAX_IDLE_CONNS`, `RATE_LIMIT_PER_MIN`, `BODY_LIMIT_MB`), dan `APP_BASE_URL` baru (untuk fix QR code). |
| `cmd/api/main.go` | Diperbaiki | `AIService`/`AIHandler` sebelumnya tidak pernah di-instantiate → fitur AI generate soal & grading esai 100% tidak bisa diakses walau kodenya sudah jadi. Sekarang di-wire. Juga meneruskan `cfg.AppBaseURL` ke `NewFormService` dan `cfg` penuh ke router. |
| `internal/interfaces/http/router/router.go` | Diperbaiki | Menambahkan grup route `/api/v1/ai/*` (sebelumnya tidak ada sama sekali → selalu 404), route `/forms/import-pdf`, memasang `BodyLimit` middleware (sudah ditulis sebelumnya tapi tidak pernah dipasang), dan meneruskan config asli ke `CORS`/`RateLimiter` alih-alih nilai hardcoded. |
| `internal/interfaces/http/middleware/cors.go` | Diperbaiki | Sebelumnya hardcoded `Access-Control-Allow-Origin: *` mengabaikan env `ALLOWED_ORIGINS`. Sekarang membaca daftar origin dari config (default tetap `*` kalau env kosong, supaya tidak ada yang tiba-tiba putus). |
| `internal/interfaces/http/handler/form_handler.go` | Diperbaiki | Ditambahkan handler `ImportPdf` (pola sama persis dengan `ImportDocx`/`ImportExcel` yang sudah ada). |
| `internal/application/service/docx_service.go` | Diperbaiki | Ditambahkan method `ImportFormFromPDF` + helper `buildFormFromExtracted` supaya tidak duplikasi ~70 baris logic yang sudah ada di versi Docx/Excel. |
| `internal/application/service/form_service.go` | Diperbaiki | **Bug**: `GetFormQRCode` sebelumnya generate QR dari `form.CustomURL` MENTAH tanpa domain apa pun (`https://quickchart.io/qr?text=ujian-ipa-8b`) — QR yang dipindai tidak mengarah ke mana pun yang valid. Sekarang memakai `AppBaseURL` + slug, dan di-encode dengan benar. |
| `internal/infrastructure/parser/pdf_parser.go` | **File baru** | Backend sebelumnya cuma bisa import Word (`docx_parser.go`) dan Excel (`excel_parser.go`) — PDF sama sekali belum didukung padahal sudah direncanakan. Parser ini ekstrak teks dari PDF lalu memakai ulang fungsi `parseLinesToForm` yang sudah ada di `docx_parser.go` (satu package `parser`), jadi format soal yang sama ("Soal 1 / A. .. / Kunci Jawaban: A") otomatis ikut jalan untuk PDF. **Batasan**: gambar di dalam PDF tidak ikut ter-ekstrak (beda dengan docx yang bisa baca gambar dari struktur zip-nya) — kalau PDF hasil scan/gambar, tidak akan ada teks yang bisa diambil sama sekali. |
| `internal/infrastructure/database/postgres.go` | Diperbaiki | Pool koneksi DB sebelumnya hardcoded `150`/`30`, mengabaikan `DB_MAX_OPEN_CONNS`/`DB_MAX_IDLE_CONNS` di `.env.example`. Sekarang dibaca dari config (default tetap sama persis kalau env tidak diisi, jadi tidak mengubah perilaku produksi saat ini). |
| `go.mod` | Diperbaiki | Menambahkan dependency `github.com/ledongthuc/pdf` untuk `pdf_parser.go`. |
| `.env.example` | Diperbaiki | Menambahkan dokumentasi `APP_BASE_URL`. |

## Yang SENGAJA Tidak Aku Sentuh

- **`RequireExambroHeader` middleware** — masih ada di `middleware/exambro_middleware.go`, tetap tidak dipasang ke route manapun. Aku tidak mengaktifkannya secara sepihak karena ini keputusan produk (apakah app Kotlin kamu sudah siap kirim header `X-Exambro-Token` di setiap request ujian). Kalau kamu mau aktifkan, tinggal tambahkan `public.Use(middleware.RequireExambroHeader())` di grup `/public` pada `router.go`.
- **Bank Soal, status "Review", batas percobaan numerik, share monitoring** — ini semua butuh migrasi skema database baru (tabel/kolom baru), bukan sekadar "perbaikan bug". Belum aku buatkan karena scope permintaanmu kali ini adalah "file yang harus dibenerin", bukan fitur baru. Bilang saja kalau mau aku lanjutkan ke situ.

## Yang Tidak Bisa Aku Verifikasi dari Sini

Sandbox ini tidak punya Go toolchain maupun akses internet, jadi aku **tidak bisa menjalankan
`go build` untuk memverifikasi** hasil akhirnya. Semua perbaikan di atas sudah aku cek manual
baris-per-baris (tipe data, nama field, import yang dipakai), tapi tolong jalankan `go build ./...`
di lokal/CI sebelum deploy ke production.
