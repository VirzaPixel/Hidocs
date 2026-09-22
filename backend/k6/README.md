# 🚀 HiDocs - k6 API Performance Testing Suite

Suite pengujian performa API lengkap untuk backend **HiDocs** menggunakan **[k6](https://k6.io/)**. Didesain dengan beban kerja realistis (*realistic workloads*), *token caching*, dan metrik performa mendalam (*latency percentiles, throughput, error rates*).

---

## 📁 Struktur Direktori

```text
k6/
├── smoke.js             # Smoke test (Beban minimal & verifikasi fungsional awal)
├── load.js              # Load test (Traffic normal dengan pola ramp-up -> steady -> ramp-down)
├── stress.js            # Stress test (Mencari titik jenuh / breaking point sistem)
├── spike.js             # Spike test (Lonjakan traffic mendadak & evaluasi recovery)
├── soak.js              # Soak / Endurance test (Uji ketahanan jangka panjang & memory leak)
├── helpers/
│   ├── config.js        # Konfigurasi Environment Variables & Custom Metrics
│   ├── auth.js          # Otentikasi & Caching Token JWT per Virtual User (VU)
│   ├── payloads.js      # Generator payload realistis (Form, Soal, Autosave, Telemetri)
│   └── workflows.js     # Skenario alur pengerjaan ujian siswa, guru/creator, & admin
└── README.md            # Dokumentasi panduan eksekusi
```

---

## ⚙️ Konfigurasi Environment Variables

Semua script mendukung kustomisasi melalui *environment variables*:

| Variable | Default Value | Deskripsi |
| :--- | :--- | :--- |
| `BASE_URL` | `http://localhost:8080` | URL dasar server backend HiDocs |
| `USER_EMAIL` | `creator@hidocs.id` | Akun guru/creator untuk simulasi CRUD & monitoring |
| `USER_PASSWORD` | `password123` | Password akun guru/creator |
| `ADMIN_EMAIL` | `admin@hidocs.id` | Akun admin untuk simulasi dashboard & realtime metrics |
| `ADMIN_PASSWORD` | `password123` | Password akun admin |
| `SOAK_DURATION` | `15m` | Durasi steady state untuk soak test |

---

## 🏃 Cara Menjalankan Test

Pastikan server backend HiDocs sudah berjalan (`go run cmd/api/main.go` atau via Docker).

### 1. Smoke Test
Memastikan API berjalan sehat tanpa error sebelum menjalankan pengujian beban besar.
```bash
k6 run k6/smoke.js
```

### 2. Load Test
Menguji performa di bawah beban operasional normal (50 concurrent users).
```bash
k6 run k6/load.js
```

### 3. Stress Test
Menaikkan beban secara bertahap (hingga 450 concurrent users) untuk menemukan batas kapasitas dan degradasi performa.
```bash
k6 run k6/stress.js
```

### 4. Spike Test
Menguji ketahanan lonjakan mendadak (10 -> 350 VUs dalam 15 detik, misal saat jam mulai ujian serentak) serta kemampuan *recovery* sistem.
```bash
k6 run k6/spike.js
```

### 5. Soak Test
Menjalankan beban stabil (40 VUs) dalam durasi panjang untuk mendeteksi *memory leak*, *connection pool exhaustion*, atau *latency creep*.
```bash
k6 run k6/soak.js
# atau dengan durasi kustom:
k6 run -e SOAK_DURATION=30m k6/soak.js
```

### Menjalankan ke Target Server / Lingkungan Lain (Staging / Production)
```bash
k6 run -e BASE_URL=https://api-staging.hidocs.id k6/load.js
```

---

## 📊 Metrik Utama yang Harus Diperhatikan

1. **`http_req_duration` (Latency)**:
   - **`p(50)` (Median)**: Pengalaman 50% pengguna normal (Target: < 150ms).
   - **`p(95)`**: Batas atas 95% request (Target: < 450ms pada load test).
   - **`p(99)`**: Latensi untuk pengguna terlambat / query berat (Target: < 1000ms).
   - **`avg`**: Rata-rata waktu respon.
2. **`http_req_failed` (Error Rate)**:
   - Persentase kegagalan HTTP (5xx, 4xx timeout, connection refused). Target: `< 1%`.
3. **`http_reqs` & Throughput (RPS)**:
   - Jumlah total request yang diproses per detik (*Requests Per Second*).
4. **`http_req_waiting` (TTFB - Time To First Byte)**:
   - Waktu tunggu proses backend sebelum mulai mengirim byte pertama ke client (indikator performa query database & handler Go).
5. **Custom Metrics**:
   - `autosave_latency_ms`: Waktu simpan jawaban siswa secara realtime.
   - `submission_latency_ms`: Waktu kalkulasi skor dan finalisasi ujian.
   - `live_monitoring_latency_ms`: Waktu query agregasi proctoring live guru.
