# HiDocs — Dynamic Form & Smart Assessment Platform

**HiDocs** adalah aplikasi *Form & Online Quiz Engine* berbasis web modern yang dirancang untuk mempermudah pembuatan, pengelolaan, dan pengisian formulir interaktif serta kuis otomatis secara terstruktur.

Aplikasi ini tidak hanya menangani formulir biasa (seperti survei atau pendaftaran), tetapi juga dilengkapi dengan sistem kuis cerdas (*smart assessment*). HiDocs mampu menangani berbagai jenis soal mulai dari pilihan ganda dengan penilaian otomatis (*auto-scoring*), soal esai, hingga soal pemrograman (*code assessment*).

Dengan arsitektur terpisah (*decoupled architecture*) antara Frontend dan Backend, HiDocs memberikan fleksibilitas, performa yang cepat, serta keamanan data dalam menangani pengerjaan kuis berdurasi (*timer-based*).

## Fitur Utama

- **Manajemen Form**: Buat, edit, hapus form dengan editor kaya, upload gambar soal (analisis gambar, maks 1 MB), jadwal buka/tutup, timer ujian, dan visibilitas publik/privat (QR-only).
- **Penilaian**: *Auto-scoring* untuk pilihan ganda/ya-tidak/rating dan *manual grading* untuk esai/kode/matematika dengan bobot per soal.
- **Keamanan Ujian**: `FLAG_SECURE` (anti screenshot), deteksi pindah aplikasi (3x peringatan → auto-submit), dan *secure canvas*.
- **Distribusi**: Link pendek, QR Code, scan, dan impor Word/Excel serta ekspor Excel/PDF.
- **Dashboard**: User (mode Creator/User), Admin (kelola creator & form + monitoring), Superadmin (kelola admin).

## Teknologi

- **Mobile**: Flutter 3.x, Provider, flutter_quill, flutter_math_fork
- **Web**: React + Vite
- **Backend**: Go (Gin), PostgreSQL, Redis, JWT, Bcrypt

## Instalasi Cepat

**Backend**
```bash
cd backend
go mod download
cp .env.example .env
go run cmd/api/main.go  # http://localhost:8088
```

**Android**
```bash
cd frontend/android
flutter pub get
cp .env.example .env  # API_BASE_URL=http://10.0.2.2:8088/api/v1
flutter run
```

**Web**
```bash
cd frontend/web
npm install && npm run dev
```

## Dokumentasi API

```bash
cd backend && swag init -g cmd/api/main.go
# buka http://localhost:8088/swagger/index.html
```

## Lisensi

MIT

