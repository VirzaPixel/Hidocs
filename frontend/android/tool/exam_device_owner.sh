#!/usr/bin/env bash
#
# exam_device_owner.sh — provision HP ujian HiDocs sebagai DEVICE OWNER.
#
# Kenapa perlu: Lock Task Mode (kiosk sejati) hanya mengunci sungguhan bila
# aplikasi berstatus device owner. Tanpa status itu, `startLockTask()` pada
# aplikasi biasa berhenti di dialog persetujuan "screen pinning" yang masih
# bisa dibatalkan siswa (lihat dokumentasi atribut `android:lockTaskMode`).
#
# Setelah skrip ini berhasil:
#   * tombol Home, daftar aplikasi terbaru, dan panel notifikasi dimatikan
#     selama siswa mengerjakan;
#   * jam + baterai TETAP tampil (LOCK_TASK_FEATURE_SYSTEM_INFO);
#   * siswa tidak punya jalan keluar sampai sesi ujian selesai.
#
# PENTING: HP harus dalam kondisi BERSIH (belum ada akun Google aktif dan
# belum ada device owner lain). `dpm set-device-owner` akan MENOLAK bila:
#   * sudah ada akun (wajib factory reset + lewati login akun), atau
#   * sudah ada device owner lain (mis. MDM) — cabut dulu.
#
# Pemakaian:
#   ./tool/exam_device_owner.sh                 # pakai APK release default
#   ./tool/exam_device_owner.sh path/app.apk    # APK lain
#   ./tool/exam_device_owner.sh --status        # hanya cek status
#   ./tool/exam_device_owner.sh --remove        # cabut device owner
#
set -euo pipefail

PACKAGE="id.hidocs.app"
RECEIVER="$PACKAGE/.ExamDeviceAdminReceiver"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEFAULT_APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"

# --- deteksi adb (ANDROID_HOME → local.properties → PATH) -------------------
resolve_adb() {
  if [[ -n "${ADB:-}" && -x "${ADB}" ]]; then echo "$ADB"; return; fi
  if [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
    echo "$ANDROID_HOME/platform-tools/adb"; return
  fi
  if [[ -f "$PROJECT_DIR/android/local.properties" ]]; then
    local sdk
    sdk="$(grep -E '^sdk\.dir=' "$PROJECT_DIR/android/local.properties" | cut -d= -f2-)"
    if [[ -n "$sdk" && -x "$sdk/platform-tools/adb" ]]; then
      echo "$sdk/platform-tools/adb"; return
    fi
  fi
  if command -v adb >/dev/null 2>&1; then command -v adb; return; fi
  echo ""
}

ADB="$(resolve_adb)"
if [[ -z "$ADB" ]]; then
  echo "ERROR: adb tidak ditemukan. Set ANDROID_HOME atau tambahkan adb ke PATH." >&2
  exit 1
fi

require_device() {
  local count
  count="$("$ADB" devices | awk 'NR>1 && $2=="device"' | wc -l | tr -d ' ')"
  if [[ "$count" -eq 0 ]]; then
    echo "ERROR: tidak ada perangkat/emulator yang terhubung." >&2
    echo "       Aktifkan USB debugging lalu jalankan 'adb devices'." >&2
    exit 1
  fi
  if [[ "$count" -gt 1 ]]; then
    echo "ERROR: lebih dari satu perangkat terhubung ($count)." >&2
    echo "       Gunakan 'adb -s <serial>' atau cabut perangkat lain." >&2
    exit 1
  fi
}

is_device_owner() {
  # `dpm list-owners` adalah sumber paling jelas; barisannya berbentuk
  # "User  0: admin=id.hidocs.app/.ExamDeviceAdminReceiver,DeviceOwner,Affiliated".
  local owners
  owners="$("$ADB" shell dpm list-owners 2>/dev/null || true)"
  if printf '%s\n' "$owners" | grep -q "$PACKAGE"; then
    printf '%s\n' "$owners" | grep -q "DeviceOwner"
    return
  fi
  # Cadangan untuk perangkat lama: nilai "Device Owner:" dicetak di baris
  # berikutnya, bukan sebaris dengan labelnya.
  "$ADB" shell dumpsys device_policy 2>/dev/null \
    | grep -A1 -i 'Device Owner:' | grep -q "$PACKAGE"
}

status_report() {
  echo "=== Status kiosk HiDocs ($PACKAGE) ==="
  if is_device_owner; then
    echo "device owner        : YA"
  else
    echo "device owner        : BELUM"
  fi
  if "$ADB" shell dpm list-owners 2>/dev/null | grep -q "$PACKAGE"; then
    echo "dpm list-owners     : terdaftar"
  else
    echo "dpm list-owners     : tidak terdaftar"
  fi
  echo "--- lock task mode ---"
  "$ADB" shell dumpsys activity activities 2>/dev/null \
    | grep -i "lockTaskModeState" | head -3 || true
}

case "${1:-}" in
  -h|--help)
    sed -n '1,40p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  --status)
    require_device
    status_report
    exit 0
    ;;
  --remove)
    require_device
    echo ">> Mencoba mencabut device owner..."
    # `dpm remove-active-admin` HANYA bisa untuk admin bertipe TEST
    # (perangkat produksi akan menolak dengan
    # "SecurityException: Attempt to remove non-test admin").
    # Karena itu kegagalan di sini bukan hal aneh — panduannya dicetak di bawah.
    if "$ADB" shell dpm remove-active-admin "$RECEIVER" 2>/dev/null; then
      echo ">> Selesai. HP kembali normal."
      exit 0
    fi
    echo ""
    echo "TIDAK BISA DICABUT dari sini (perilaku Android, bukan bug skrip):"
    echo "  'dpm remove-active-admin' hanya berlaku untuk admin bertipe TEST."
    echo "  Pemanggilan sekarang ditolak dengan:"
    echo "    SecurityException: Attempt to remove non-test admin"
    echo ""
    echo "Pilihan yang tersedia:"
    echo "  1. Factory reset HP — cara pasti untuk device owner produksi."
    echo "     Backup data penting lebih dulu."
    echo "  2. Bila HP ini dipakai untuk uji coba: pasang ulang APK dengan"
    echo "     'adb install -r -t <apk>' SEBELUM menjadikannya device owner,"
    echo "     supaya admin tercatat sebagai test admin dan bisa dicabut."
    echo "     Untuk owner yang sudah terpasang sekarang, tetap perlu langkah 1."
    echo "  3. Settings → Security → Device admin apps TIDAK bisa menonaktifkan"
    echo "     device owner; jangan diandalkan."
    exit 1
    ;;
esac

APK="${1:-$DEFAULT_APK}"

if [[ ! -f "$APK" ]]; then
  echo "ERROR: APK tidak ditemukan: $APK" >&2
  echo "       Bangun dulu: flutter build apk --release" >&2
  exit 1
fi

require_device

echo "=== Provision HiDocs sebagai device owner ==="
echo "APK    : $APK"
echo "Paket  : $PACKAGE"
echo ""

# 1. Pasang APK (upgrade aman dengan -r, tapi TIDAK dengan -d: turun versi
#    pada device owner bisa ditolak sistem).
echo ">> [1/3] Memasang APK..."
"$ADB" install -r "$APK"

# 2. Pastikan status bersih sebelum set device owner.
echo ">> [2/3] Memeriksa device owner yang ada..."
# 'dpm list-owners' mencetak baris "no owners" bila belum ada owner sama sekali,
# jadi baris itu (dan baris kosong) harus disaring dulu.
OWNERS_RAW="$("$ADB" shell dpm list-owners 2>/dev/null || true)"
OWNERS="$(printf '%s\n' "$OWNERS_RAW" \
  | grep -v '^[[:space:]]*no owners[[:space:]]*$' \
  | sed '/^[[:space:]]*$/d' || true)"
if [[ -n "$OWNERS" ]] && ! printf '%s\n' "$OWNERS" | grep -q "$PACKAGE"; then
  echo "ERROR: sudah ada device owner lain di perangkat ini:" >&2
  printf '%s\n' "$OWNERS" >&2
  echo "Cabut dulu (factory reset bila perlu), lalu ulangi." >&2
  exit 1
fi

# 3. Set device owner. Bila gagal karena akun aktif, pesan dari sistem sudah
#    menjelaskan penyebabnya.
echo ">> [3/3] Menetapkan device owner..."
if ! OUT="$("$ADB" shell dpm set-device-owner "$RECEIVER" 2>&1)"; then
  echo "GAGAL: $OUT" >&2
  echo "" >&2
  echo "Penyebab paling umum:" >&2
  echo "  * Sudah ada akun Google aktif  → factory reset, lewati login akun." >&2
  echo "  * Sudah ada device owner lain  → cabut MDM/admin lama lebih dulu." >&2
  echo "  * Beberapa perangkat            → aktifkan 'oem unlock' lebih dulu." >&2
  exit 1
fi
echo "$OUT"

echo ""
status_report
echo ""
echo ">> Selesai. Buka ulang aplikasi HiDocs, lalu masuk ke halaman"
echo "   'Persiapan Ujian' — kartu 'Kunci Kiosk Sejati' harus berwarna hijau."
