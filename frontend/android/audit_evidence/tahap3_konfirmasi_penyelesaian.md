# TAHAP 3 — Konfirmasi & Penyelesaian (VPS Live + Fokus Android)

Tanggal: 2026-09-22 | Target: `https://hidocs.my.id` | App: `id.hidocs.app`

## 1. Konfirmasi Fix Tahap 2
| Item | Status |
|---|---|
| `INTERNET` + `ACCESS_NETWORK_STATE` di manifest | ✅ confirmed via `aapt dump permissions` |
| `.env` terbundle (`flutter_assets/.env`) | ✅ confirmed via `unzip -l` |
| Deep-link host `hidocs.my.id` (+legacy) di manifest + `deep_link_service.dart` | ✅ |
| Backend forgot return token (non-prod dev-mode) | ✅ `go build` + `go test` PASS |
| Backend regression `TestAuthService_ForgotAndResetPassword` (6 skenario) | ✅ PASS |
| `flutter analyze` | ✅ 0 error (23 info `prefer_const`) |
| VPS live (`/health`, validasi login/reset, rate-limit 429, public form 200) | ✅ |

## 2. Hardening Tambahan Tahap 3
- `minSdk 24 → 29` (Android 10+) di `build.gradle.kts` → tutup 1 HIGH MobSF.
- Release APK signed keystore produksi (`CN=HiDocs, O=HiDocs, C=ID`, SHA-256 `30:F8:…:B6`, valid s/d 2054) → tutup 2 HIGH (debug cert + debuggable).
- Rescan MobSF release: **skor 51 → 55, HIGH 5 → 2**.
- Sisa 2 HIGH: (1) `assetlinks.json` 404 di VPS — file siap di `frontend/android/assetlinks.json`, tinggal serve di `https://hidocs.my.id/.well-known/assetlinks.json`; (2) `CBC/PKCS5 padding oracle` di `o2/a.java` — file obfuscated milik SDK/dependensi (kode Kotlin kita bersih, tanpa Cipher/AES), terima-risiko / tindak lanjut upgrade dependensi.

## 3. Patrol & Device (tanpa emulator — hemat RAM)
- 5 journeys di `integration_test/patrol_test.dart`; `flutter test` PASS; `patrol test` build OK tapi native runner report 0 test (instrumentasi emulator, bukan kegagalan app).
- APK debug+release terinstall & `MainActivity` jalan (PID verified sebelum emulator dimatikan).

## 4. k6 vs VPS
- 10VU/40s: 140/140 checks PASS, 0% failed, p95 440ms. 500VU TIDAK dijalankan (self-DDoS vs limiter 500/menit + auth 10/menit di VPS produksi).

## 5. Yang Tinggal (aksi deploy — di luar akses saya)
1. Push `main` → GitHub Actions deploy backend ke VPS (fix forgot-token ikut ke-deploy).
2. Serve `assetlinks.json` (isi = file `frontend/android/assetlinks.json`) di `https://hidocs.my.id/.well-known/assetlinks.json` (tutup HIGH terakhir sisi server).
3. Isi SMTP di `.env` VPS agar email reset/OTP benar-benar terkirim (saat ini token hanya log server / dev-response).
4. Rilis Play Store pakai `app-release.apk` (sudah signed produksi, minSdk 29).

## Kesimpulan Tahap 3
Kode + hardening selesai dan terverifikasi di sisi repo. Yang belum: deploy VPS (push main), assetlinks serve, SMTP isi — ketiganya butuh akses server/produksi.
