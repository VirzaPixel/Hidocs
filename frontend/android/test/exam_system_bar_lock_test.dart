import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regresi "status bar HP masih bisa di-swipe saat ujian".
///
/// Akarnya ada di kode Kotlin, jadi tidak bisa dijangkau widget test. Yang
/// dikunci di sini adalah KONTRAK-nya: saat mengunci layar ujian, native
/// HARUS memakai [WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE]
/// (nilai 2), BUKAN `BEHAVIOR_DEFAULT` (nilai 1).
///
/// Kenapa penting: pada androidx `WindowInsetsControllerCompat`,
/// `BEHAVIOR_DEFAULT = BEHAVIOR_SHOW_BARS_BY_SWIPE = 1`. Dokumentasi resminya
/// menyatakan pada mode itu bar tersembunyi "can be revealed with system
/// gestures, such as swiping from the edge of the screen where the bar is
/// hidden from" — artinya memakai `BEHAVIOR_DEFAULT` sama saja mengizinkan
/// siswa menarik status bar keluar. Hanya mode TRANSIENT yang memunculkannya
/// sebagai overlay sementara yang tidak interaktif.
void main() {
  late String bridge;

  setUpAll(() {
    final file = File(
      'android/app/src/main/kotlin/id/hidocs/app/SecurityBridge.kt',
    );
    expect(file.existsSync(), isTrue,
        reason: 'SecurityBridge.kt harus ada untuk memeriksa kontrak native');
    bridge = file.readAsStringSync();
  });

  test('kunci fullscreen memakai BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE', () {
    expect(
      bridge.contains(
        'WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE',
      ),
      isTrue,
      reason: 'system bar harus muncul hanya sementara dan tidak interaktif',
    );
  });

  test('kunci fullscreen TIDAK memakai BEHAVIOR_DEFAULT (= bisa di-swipe)', () {
    expect(
      bridge.contains('WindowInsetsControllerCompat.BEHAVIOR_DEFAULT'),
      isFalse,
      reason: 'BEHAVIOR_DEFAULT == BEHAVIOR_SHOW_BARS_BY_SWIPE (1): '
          'status bar bisa ditarik lewat geseran tepi layar',
    );
  });

  test('ada watchdog yang menutup ulang system bar', () {
    expect(bridge.contains('systemBarWatchdog'), isTrue);
    expect(bridge.contains('isSystemBarVisible'), isTrue);
    expect(bridge.contains('SYSTEM_BAR_WATCHDOG_MS'), isTrue);
  });

  test('screen pinning tersedia dan dilepas saat ujian selesai', () {
    expect(bridge.contains('fun startExamLockTask'), isTrue);
    expect(bridge.contains('fun stopExamLockTask'), isTrue);
    expect(bridge.contains('fun isExamLockTaskActive'), isTrue);
    expect(
      bridge.contains('"startExamLockTask" ->'),
      isTrue,
      reason: 'harus terdaftar di method channel',
    );
    expect(bridge.contains('"stopExamLockTask" ->'), isTrue);
  });

  test('screen pinning dilepas di dispose (siswa tidak tertahan)', () {
    final dispose = bridge.substring(
      bridge.indexOf('fun dispose()'),
      bridge.indexOf('/**', bridge.indexOf('fun dispose()')),
    );
    expect(dispose.contains('stopExamLockTask()'), isTrue);
    expect(dispose.contains('stopSystemBarWatchdog()'), isTrue);
  });
}
