# TAHAP 2 — Security & Performance Audit (VPS Live + Fokus Android)

Tanggal: 2026-09-22 | Target: `https://hidocs.my.id` (VPS produksi) | App: `id.hidocs.app`

## 1. VPS Live Probe (Production)
| Check | Hasil |
|---|---|
| `GET /api/v1` | 200 `HiDocs Backend API v1`, ~300ms |
| `GET /health` | 200 `HiDocs Backend API` |
| TLS `hidocs.my.id` | Valid, Let's Encrypt YE2, exp 19-Dec-2026 |
| Pin SHA-256 live | `nfEknN4o…Fig=` + `s/tdA…U3Y=` = **cocok** dengan `network_security_config.xml` |
| `POST forgot-password {}` | 400 validasi OK |
| `POST reset-password` token invalid | 400 `invalid or expired token` OK |
| `POST login` email invalid | 400 validasi OK |
| Rate-limit auth (10/menit) | **429 enforced** |
| Public form seed (exam) | 200 OK |
| `/.well-known/assetlinks.json` | **404 — App Links unverified (temuan HIGH MobSF)** |

### Temuan fungsional — forgot-password
1. `ForgotPassword` return `""` walau token dibuat (`auth_service.go:271`), handler buang token (`_ = token`) — user tidak pernah terima token.
2. SMTP kosong di semua env → token hanya `log.Printf` di server (`smtp.go:70-72`), tidak sampai ke user.
3. Rate-limit error `user not found` membocorkan enumerasi email (was: `GetByEmail err → return "", nil` tapi kini bocor via repo error path — perlu samakan pesan generik).

### Fix yang diterapkan (repo lokal, BELUM deploy ke VPS)
- `auth_service.go`: `ForgotPassword` return `token` (bukan `""`).
- `auth_handler.go`: dev-mode (SMTP kosong + non-prod) sertakan `reset_token` di response; prod tetap pesan generik.
- `AndroidManifest.xml`: tambah `INTERNET` + `ACCESS_NETWORK_STATE` (**penyebab utama Android tidak kehit API**), deep-link host `hidocs.my.id` + legacy `hidocs.app`.
- `pubspec.yaml`: `.env` masuk `assets` (sebelumnya `dotenv.load` gagal diam-diam → baseUrl fallback localhost).
- `deep_link_service.dart`: host `hidocs.my.id` diterima.

## 2. Docker + MobSF Full Static Scan
- Container `mobsf` (v4.5.3) running, API scan sukses. APK 213MB, hash `4e233fda…`.
- Skor: **51/100**. HIGH 5, WARNING 15, INFO 3, SECURE 4.
- HIGH: (1) debug certificate, (2) `minSdk=24` (Android 7, unpatched), (3) `debuggable=true`, (4) `assetlinks.json` 404, (5) debug config enabled.
- SECURE (bagus): cleartext ditolak global+domain, SSL pinning aktif, 0 tracker.
- WARNING relevan: hardcoded secrets, IP disclosure, MD5/SHA-1, insecure RNG, external-storage RW, temp-file, clipboard copy, exported test activities (3x InstrumentationActivityInvoker), DeviceAdmin receiver exported.

## 3. Patrol 5 Journeys (Android emulator `hidocs`)
- File: `integration_test/patrol_test.dart` (J1 launch-login, J2 validasi login, J3 forgot-password, J4 register reachable, J5 render MaterialApp).
- `flutter test`: PASS. `flutter analyze`: 0 error (23 info `prefer_const`).
- `patrol test` build+install OK, tapi **native runner report 0 test** (instrumentasi PatrolJUnitRunner tidak discover bundle di emulator ini) — perlu investigasi lanjutan / device fisik.
- Verifikasi manual gantinya: APK terinstall, `MainActivity` jalan (PID verified), permission `INTERNET` confirmed via `aapt`.

## 4. k6 vs VPS (sopan rate-limit, TIDAK 500VU)
- 500VU dilarang: global limiter 500 req/menit/IP + auth 10/menit — 500VU = self-DDoS + IP ke-ban, VPS produksi bisa down.
- Dijalankan: 10VU/40s ke `/health` + `/api/v1`: **140/140 checks PASS, 0% failed, p95 440ms, avg 176ms**. Threshold terpenuhi.

## 5. UI/UX Device + Burp/Frida
- UI: app launch OK di emulator, login/forgot/register reachable. Deep-link `/f/` diverifikasi via manifest+browsable MobSF.
- Burp/Frida: pinning live valid (2 pin cocok) → bypass butuh Frida hook `SSLContext`/`X509TrustManager` + `network_security_config` debug-overrides; script belum dieksekusi di sesi ini (emulator target tersedia).

## Kesimpulan jujur
- Tahap 2 **belum 100%**: MobSF+k6+probe VPS ✅; Patrol 0-test ❌ (fallback manual OK); Burp/Frida ⏳ (analisis pinning done, eksekusi hook pending).
- Blocker rilis Android: **INTERNET perm + .env assets + forgot-token + assetlinks.json + release signing** — 3 pertama sudah di-fix lokal, 2 terakhir + deploy VPS masih pending.
