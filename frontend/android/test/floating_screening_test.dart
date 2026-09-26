import 'package:flutter_test/flutter_test.dart';

import 'package:hi_docs/services/security/exam_security_service.dart';
import 'package:hi_docs/services/security/floating_app_catalog.dart';

/// Satu entri persis seperti yang dikirim native `getInstalledApps`.
Map<String, Object?> nativeApp({
  required String pkg,
  required String label,
  bool active = false,
  bool system = false,
  bool declaresOverlay = true,
  bool overlayGranted = true,
}) {
  return <String, Object?>{
    'packageName': pkg,
    'appName': label,
    'isFloatingActive': active,
    'isSystem': system,
    'declaresOverlayPermission': declaresOverlay,
    'overlayPermissionGranted': overlayGranted,
    'isRunning': active,
    'matchedFloatingLabel': '',
  };
}

/// Bentuk payload native baru: daftar aplikasi + total aplikasi terpasang.
Object payloadOf(List<Map<String, Object?>> apps, {int? total}) =>
    <String, Object?>{'apps': apps, 'totalInstalled': total ?? apps.length};

void main() {
  group('ID paket asli hasil verifikasi Play Store', () {
    test('Floatee = com.maika.floatee dikenali sebagai alat floating', () {
      final c = classifyFloatingTool(
        packageName: 'com.maika.floatee',
        appName: 'Floatee',
      );
      expect(c.isDedicatedFloatingTool, isTrue);
      expect(c.catalogEntry?.androidPackage, 'com.maika.floatee',
          reason: 'harus ada di katalog, bukan hanya tebakan dari nama');
    });

    test('Floating Apps (LWi) versi gratis & berbayar dikenali', () {
      for (final pkg in [
        'com.lwi.android.flapps',
        'com.lwi.android.flappsfull',
      ]) {
        final c =
            classifyFloatingTool(packageName: pkg, appName: 'Floating Apps');
        expect(c.isDedicatedFloatingTool, isTrue, reason: pkg);
      }
    });

    test('varian paket berakhalan dikenal (com.lwi.android.flappsfull)', () {
      expect(
        findCatalogEntry('com.lwi.android.flappsfull')?.androidPackage,
        'com.lwi.android.flappsfull',
      );
    });
  });

  group('screening seluruh aplikasi terpasang', () {
    test('Floatee + Floating Apps menghalangi mulai ujian', () {
      final result = screenInstalledPayload(payloadOf(
        [
          nativeApp(pkg: 'com.maika.floatee', label: 'Floatee'),
          nativeApp(pkg: 'com.lwi.android.flapps', label: 'Floating Apps'),
          nativeApp(pkg: 'com.whatsapp', label: 'WhatsApp'),
        ],
        total: 213,
      ));

      expect(result.scanSupported, isTrue);
      expect(result.scanFailed, isFalse);
      expect(
        result.blocking.map((e) => e.packageName),
        containsAll(<String>['com.maika.floatee', 'com.lwi.android.flapps']),
      );
      expect(
        result.blocking.map((e) => e.packageName),
        isNot(contains('com.whatsapp')),
        reason: 'WhatsApp hanya aplikasi harian pembuat bubble',
      );
      expect(result.totalInstalled, 213,
          reason: 'jumlah pemindaian = total aplikasi, bukan hanya temuan');
      expect(result.isClean, isFalse);
    });

    test('alat floating yang TIDAK ADA di katalog tetap tertangkap', () {
      // Kelas bug yang membuat pendekatan berbasis katalog saja selalu kalah:
      // aplikasi baru/aneh yang belum terdaftar tetap bisa melayang.
      final result = screenInstalledPayload(payloadOf(
        [nativeApp(pkg: 'com.anonim.perkakas', label: 'Perkakas Aneh')],
        total: 120,
      ));

      expect(result.blocking, hasLength(1));
      expect(result.blocking.single.kind, FloatingFindingKind.installedTool);
    });
    test('aplikasi harian ber-izin overlay hanya jadi catatan, tidak mengunci',
        () {
      final result = screenInstalledPayload(payloadOf(
        [
          nativeApp(pkg: 'com.facebook.orca', label: 'Messenger'),
          nativeApp(pkg: 'org.telegram.messenger', label: 'Telegram'),
        ],
        total: 90,
      ));

      expect(result.blocking, isEmpty);
      expect(result.informational, hasLength(2));
      expect(result.isClean, isTrue);
    });

    test('aplikasi sistem tidak pernah mengunci pengguna', () {
      final result = screenInstalledPayload(payloadOf(
        [
          nativeApp(
              pkg: 'com.miui.securitycenter', label: 'Security', system: true),
          nativeApp(
            pkg: 'com.samsung.android.sdk.oparts',
            label: 'OneHand',
            system: true,
          ),
        ],
        total: 180,
      ));
      expect(result.blocking, isEmpty,
          reason: 'tidak bisa di-uninstall = tidak adil memblokir ujian');
    });

    test('aplikasi sistem yang sedang menayangkan overlay tetap diblokir', () {
      final result = screenInstalledPayload(payloadOf(
        [
          nativeApp(
            pkg: 'com.oem.floatwindow',
            label: 'Float Window',
            system: true,
            active: true,
          ),
        ],
        total: 180,
      ));
      expect(result.blocking, hasLength(1));
      expect(result.blocking.single.kind, FloatingFindingKind.activeOverlay);
    });

    test('aplikasi penting dan HiDocs sendiri tidak pernah ditandai', () {
      final result = screenInstalledPayload(payloadOf(
        [
          nativeApp(pkg: 'com.android.dialer', label: 'Phone'),
          nativeApp(pkg: 'com.android.systemui', label: 'System UI'),
          nativeApp(pkg: 'id.hidocs.app', label: 'HiDocs'),
        ],
        total: 100,
      ));
      expect(result.blocking, isEmpty);
      expect(result.informational, isEmpty);
    });

    test('temuan ganda untuk satu package dipadatkan', () {
      final result = screenInstalledPayload(payloadOf(
        [
          nativeApp(pkg: 'com.maika.floatee', label: 'Floatee'),
          nativeApp(pkg: 'com.maika.floatee', label: 'Floatee'),
        ],
        total: 70,
      ));
      expect(result.blocking, hasLength(1));
    });
  });

  group('fail-closed: pemindaian gagal tidak boleh dibaca "bersih"', () {
    test('payload null berarti gagal, bukan bersih', () {
      final result = screenInstalledPayload(null);
      expect(result.scanFailed, isTrue);
      expect(result.isClean, isFalse,
          reason:
              'gerbang ujian dulu menyala hijau walau tidak ada pemindaian');
    });

    test('nol aplikasi pada perangkat yang pasti terisi = gagal enumerasi', () {
      final result = screenInstalledPayload(payloadOf(const [], total: 0));
      expect(result.scanFailed, isTrue);
      expect(result.isClean, isFalse);
    });

    test('nol temuan pada perangkat yang jelas terisi = bersih sungguhan', () {
      final result = screenInstalledPayload(payloadOf(
        [nativeApp(pkg: 'com.whatsapp', label: 'WhatsApp')],
        total: 200,
      ));
      expect(result.scanFailed, isFalse);
      expect(result.isClean, isTrue);
    });

    test('payload bentuk lama (List polos) tetap terbaca', () {
      final result = screenInstalledPayload([
        nativeApp(pkg: 'com.maika.floatee', label: 'Floatee'),
      ]);
      expect(result.blocking.map((e) => e.packageName),
          contains('com.maika.floatee'));
    });
  });

  group('mode live selama ujian berlangsung', () {
    test('hanya overlay yang sedang tampil yang dilaporkan', () {
      final result = screenInstalledPayload(
        payloadOf(
          [
            nativeApp(pkg: 'com.maika.floatee', label: 'Floatee', active: true),
            nativeApp(pkg: 'com.anonim.something', label: 'Anonim'),
          ],
          total: 200,
        ),
        liveOnly: true,
      );
      expect(result.blocking, hasLength(1));
      expect(result.informational, isEmpty);
    });
  });
}

