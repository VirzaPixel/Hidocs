import 'package:flutter/material.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/screens/exam/exam_token_screen.dart';
import 'package:hi_docs/screens/forms/fill_form_screen.dart';
import 'package:hi_docs/services/security/exam_lockdown_service.dart';
import 'package:hi_docs/services/security/exam_security_service.dart';
import 'package:hi_docs/utils/custom_page_route.dart';
import 'package:hi_docs/utils/theme_context.dart';

/// Gerbang wajib sebelum mengerjakan ujian.
///
/// Sesuai "Revisi Lanjutan 8", halaman ini FOKUS hanya pada tiga hal:
///  1. Screening aplikasi floating yang terpasang/aktif (harus bersih).
///  2. Izin "tampil di atas aplikasi lain" untuk HiDocs.
///  3. Informasi volume HP (informasi pasif + alarm keluar).
///
/// Syarat "sesi ujian terdaftar (response id)" DIHAPUS dari halaman ini.
/// Pencatatan sesi terjadi di langkah berikutnya, yaitu layar token
/// ([ExamTokenScreen]) lewat endpoint `verify-token`. Urutan alurnya:
///
///   detail form → GERBANG ini → layar token (tipe ujian) → pengisian.
///
/// Selama syarat 1 dan 2 belum terpenuhi, tombol "Mulai Ujian" terkunci.
class ExamLockdownGateScreen extends StatefulWidget {
  final FormModel form;

  const ExamLockdownGateScreen({
    required this.form,
    super.key,
  });

  @override
  State<ExamLockdownGateScreen> createState() => _ExamLockdownGateScreenState();
}

class _ExamLockdownGateScreenState extends State<ExamLockdownGateScreen>
    with WidgetsBindingObserver {
  LockdownReadiness? _readiness;
  bool _loading = true;
  bool _engaging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Halaman ini BUKAN sesi ujian: pastikan tidak ada alarm keluar maupun
    // kunci layar yang masih menyala dari percobaan sebelumnya, sehingga
    // siswa boleh menutup aplikasi tanpa suara alarm.
    ExamLockdownService.ensureIdle();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Setelah kembali dari layar Settings, periksa ulang otomatis.
    if (state == AppLifecycleState.resumed && mounted) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final result = await ExamLockdownService.evaluate();
    if (!mounted) return;
    setState(() {
      _readiness = result;
      _loading = false;
    });
  }

  /// Lanjut dari halaman persiapan ke langkah berikutnya.
  ///
  /// Alur baru: gerbang ini TIDAK lagi memeriksa sesi terdaftar. Untuk tipe
  /// ujian, langkah berikutnya adalah layar token ([ExamTokenScreen]) — di
  /// sanalah token dimasukkan dan sesi ujian dicatat lewat `verify-token`.
  /// Form non-ujian langsung masuk ke pengisian.
  Future<void> _startExam() async {
    final ready = _readiness;
    if (ready == null || !ready.isReady || _engaging) {
      return;
    }

    setState(() => _engaging = true);

    // CATATAN: `engage()` SENGAJA tidak dipanggil di sini. Halaman ini hanya
    // memeriksa perangkat (read-only). Volume penuh + alarm keluar baru
    // dinyalakan oleh [FillFormScreen] saat siswa benar-benar mulai mengisi —
    // kalau dipasang di sini, suara alarm keluar ikut berbunyi saat siswa
    // masih di layar masukan token.
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      CustomPageRoute(
        page: widget.form.formType == FormType.exam
            ? ExamTokenScreen(form: widget.form)
            : FillFormScreen(form: widget.form),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDark;
    final ready = _readiness;
    final isReady = ready?.isReady ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          l10n.isIndonesian ? 'Persiapan Ujian' : 'Exam Setup',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading && ready == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  const _GateStepIndicator(),
                  const SizedBox(height: 14),
                  _HeaderCard(isReady: isReady, dark: isDark),
                  const SizedBox(height: 20),

                  _SectionTitle(
                    title: l10n.isIndonesian
                        ? 'Proses 1 — Screening Seluruh Aplikasi'
                        : 'Step 1 — Full App Screening',
                    subtitle: l10n.isIndonesian
                        ? 'Semua aplikasi yang terpasang di HP diperiksa, lalu '
                              'dikategorikan: alat floating khusus (harus '
                              'dihapus/ditutup), aplikasi yang sedang '
                              'menayangkan overlay, dan aplikasi umum yang '
                              'hanya punya fitur bubble (tidak menghalangi).'
                        : 'Every installed app is scanned and categorized: dedicated floating tools (must be removed/closed), apps currently showing an overlay, and mainstream apps that merely have bubble features (not blocking).',
                  ),
                  const SizedBox(height: 10),
                  _FloatingAppsCard(
                    screening: ready?.screening,
                    dark: isDark,
                  ),
                  const SizedBox(height: 20),

                  _SectionTitle(
                    title: l10n.isIndonesian
                        ? 'Proses 2 — Izin Tampil di Atas Aplikasi'
                        : 'Step 2 — Draw Over Other Apps',
                    subtitle: l10n.isIndonesian
                        ? 'HiDocs butuh izin ini; sekaligus memastikan tidak ada aplikasi lain yang overlay.'
                        : 'HiDocs needs this permission while ensuring no other app overlays.',
                  ),
                  const SizedBox(height: 10),
                  _RequirementCard(
                    icon: Icons.layers_rounded,
                    title: l10n.isIndonesian
                        ? 'Izin Overlay HiDocs'
                        : 'HiDocs Overlay Permission',
                    description: l10n.isIndonesian
                        ? 'Wajib aktif supaya peringatan pelanggaran bisa menutup layar.'
                        : 'Required so violation warnings can cover the screen.',
                    satisfied: ready?.overlayPermissionOk ?? false,
                    dark: isDark,
                    onAction: () => ExamSecurityService.openOverlaySettings(),
                  ),
                  const SizedBox(height: 20),

                  _SectionTitle(
                    title: l10n.isIndonesian
                        ? 'Proses 3 — Kunci Kiosk (Device Owner)'
                        : 'Step 3 — Kiosk Lock (Device Owner)',
                    subtitle: l10n.isIndonesian
                        ? 'Saat siswa mengerjakan, tombol Home, daftar aplikasi '
                              'terbaru, dan panel notifikasi dimatikan total. '
                              'Jam + baterai tetap tampil dari sistem.'
                        : 'While working, Home, Recents, and the notification '
                              'panel are fully disabled. Clock + battery stay '
                              'visible from the system.',
                  ),
                  const SizedBox(height: 10),
                  _KioskCard(kiosk: ready?.kiosk, dark: isDark),
                  const SizedBox(height: 20),

                  // "Fitur volume otomatis" (kartu interaktif + tombol tes)
                  // DIHAPUS sesuai permintaan. Yang tersisa hanya informasi:
                  // volume media dibuat 100% otomatis saat mengerjakan ujian
                  // dan dipulihkan saat keluar, serta alarm keluar berbunyi.
                  _ExamNoticeCard(dark: isDark),
                  const SizedBox(height: 24),

                  _ChecklistSummary(
                    ready: ready,
                    dark: isDark,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _BottomAction(
        isReady: isReady,
        isEngaging: _engaging,
        onStart: _startExam,
        onRefresh: _refresh,
        // Tipe ujian lanjut ke layar token, bukan langsung pengisian.
        readyLabel: widget.form.formType == FormType.exam
            ? (l10n.isIndonesian
                ? 'Lanjut Ke Token Ujian'
                : 'Continue to Exam Token')
            : (l10n.isIndonesian ? 'Mulai Ujian' : 'Start Exam'),
      ),
    );
  }
}

class _GateStepIndicator extends StatelessWidget {
  const _GateStepIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(1, active: true),
        _stepLine(),
        _stepDot(2),
      ],
    );
  }

  Widget _stepDot(int n, {bool done = false, bool active = false}) {
    final color =
        done || active ? AppTheme.success : AppTheme.textMuted;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || active ? color.withValues(alpha: 0.15) : null,
        border: Border.all(color: color),
      ),
      child: Center(
        child: done
            ? Icon(Icons.check_rounded, size: 14, color: color)
            : Text('$n',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
      ),
    );
  }

  Widget _stepLine() => Container(
        width: 28,
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppTheme.textMuted.withValues(alpha: 0.35),
      );
}

class _HeaderCard extends StatelessWidget {
  final bool isReady;
  final bool dark;

  const _HeaderCard({required this.isReady, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isReady ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isReady ? Icons.verified_user_rounded : Icons.shield_outlined,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady
                      ? (l10n.isIndonesian
                          ? 'Perangkat Siap'
                          : 'Device Ready')
                      : (l10n.isIndonesian
                          ? 'Perangkat Belum Siap'
                          : 'Device Not Ready'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isReady
                      ? (l10n.isIndonesian
                          ? 'Semua syarat terpenuhi. Anda bisa mulai ujian.'
                          : 'All requirements met. You may start the exam.')
                      : (l10n.isIndonesian
                          ? 'Penuhi semua syarat di bawah sebelum mulai.'
                          : 'Complete all requirements below before starting.'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ganti "fitur volume otomatis" yang lama (kartu interaktif + tombol tes).
///
/// Sekarang HANYA informasi pasif: volume media akan dinaikkan ke 100% secara
/// otomatis pada saat mengerjakan ujian (dan dipulihkan saat keluar), serta
/// suara `assets/keluar.mp3` berbunyi ketika pengguna keluar aplikasi.
class _ExamNoticeCard extends StatelessWidget {
  final bool dark;

  const _ExamNoticeCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final notes = <(IconData, String)>[
      (
        Icons.volume_up_rounded,
        l10n.isIndonesian
            ? 'Volume HP akan otomatis dibuat 100% (penuh) selama Anda '
                  'mengerjakan ujian, lalu dikembalikan seperti semula saat '
                  'keluar. Tidak perlu diatur manual.'
            : 'Phone volume is automatically set to 100% while you take the '
                  'exam, then restored when you leave. No manual setup needed.',
      ),
      (
        Icons.campaign_rounded,
        l10n.isIndonesian
            ? 'Jika Anda keluar dari aplikasi saat ujian berlangsung, suara '
                  'peringtan (alarm) akan langsung berbunyi.'
            : 'If you leave the app during the exam, an alarm sound plays '
                  'immediately.',
      ),
      (
        Icons.lock_rounded,
        l10n.isIndonesian
            ? 'Layar ujian juga dikunci: screenshot dan preview di daftar '
                  'aplikasi terbaru diblokir.'
            : 'The exam screen is also secured: screenshots and recents '
                  'previews are blocked.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (dark ? AppTheme.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.isIndonesian
                      ? 'Berjalan Otomatis (tanpa pengaturan)'
                      : 'Runs automatically (no setup)',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (icon, text) in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: dark ? AppTheme.accent : AppTheme.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: dark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _FloatingAppsCard extends StatelessWidget {
  final FloatingAppScreeningResult? screening;
  final bool dark;

  const _FloatingAppsCard({required this.screening, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = screening;

    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!data.scanSupported) {
      return _infoBox(
        icon: Icons.info_outline_rounded,
        color: AppTheme.info,
        title: l10n.isIndonesian
            ? 'Daftar aplikasi tidak terbaca di perangkat ini'
            : 'Installed app list unavailable on this device',
        lines: [
          l10n.isIndonesian
              ? 'Ujian tetap dapat dimulai, namun pantau layar Anda.'
              : 'Exam can still start, but stay focused on screen.',
        ],
      );
    }

    if (data.isClean) {
      return _infoBox(
        icon: Icons.check_circle_rounded,
        color: AppTheme.success,
        title: l10n.isIndonesian
            ? 'Bersih — ${data.totalScanned} aplikasi diperiksa'
            : 'Clean — ${data.totalScanned} apps scanned',
        lines: [
          l10n.isIndonesian
              ? 'Tidak ada aplikasi floating yang terdeteksi menghalangi ujian.'
              : 'No floating app detected that blocks the exam.',
          if (data.informational.isNotEmpty)
            l10n.isIndonesian
                ? '${data.informational.length} aplikasi umum punya fitur '
                      'bubble/overlay tetapi tidak sedang menayangkannya.'
                : '${data.informational.length} mainstream apps have bubble/'
                      'overlay features but are not showing them.',
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.isIndonesian
                      ? '${data.blocking.length} aplikasi floating terdeteksi '
                            'dari ${data.totalScanned} aplikasi diperiksa'
                      : '${data.blocking.length} floating apps detected '
                            'out of ${data.totalScanned} scanned',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.isIndonesian
                ? 'Tekan "Kelola" pada aplikasi tersebut untuk menghentikan '
                      'paksa, mencabut izin overlay, atau menghapusnya. '
                      'Setelah itu tekan "Periksa Ulang".'
                : 'Tap "Manage" on each app to force-stop it, revoke its '
                      'overlay permission, or uninstall it. Then tap '
                      '"Re-check".',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...data.blocking.map(
            (app) => _FloatingFindingTile(app: app, dark: dark),
          ),
          if (data.informational.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InformationalAppsDisclosure(apps: data.informational, dark: dark),
          ],
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> lines,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                for (final line in lines) ...[
                  const SizedBox(height: 4),
                  Text(
                    line,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: dark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu temuan aplikasi floating yang menghalangi ujian.
class _FloatingFindingTile extends StatelessWidget {
  final InstalledAppInfo app;
  final bool dark;

  const _FloatingFindingTile({required this.app, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = app.kind == FloatingFindingKind.activeOverlay;
    final badgeColor = active ? AppTheme.error : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${app.category} · risiko ${app.riskLevel}/3 · '
                    '${app.why}',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: dark
                          ? AppTheme.darkTextMuted
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => ExamSecurityService.openAppSettings(
                app.packageName,
              ),
              style: TextButton.styleFrom(
                foregroundColor: badgeColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.isIndonesian ? 'Kelola' : 'Manage',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aplikasi umum ber-kemampuan bubble: dilaporkan, tidak memblokir.
class _InformationalAppsDisclosure extends StatelessWidget {
  final List<InstalledAppInfo> apps;
  final bool dark;

  const _InformationalAppsDisclosure({
    required this.apps,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            iconColor: AppTheme.textMuted,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          title: Text(
            l10n.isIndonesian
                ? '${apps.length} aplikasi umum punya fitur bubble '
                      '(tidak menghalangi)'
                : '${apps.length} mainstream apps have bubble features '
                      '(not blocking)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                apps.map((a) => a.displayName).join(', '),
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool satisfied;
  final bool dark;
  final VoidCallback onAction;

  const _RequirementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.satisfied,
    required this.dark,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = satisfied ? AppTheme.success : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: satisfied
              ? color.withValues(alpha: 0.35)
              : (dark ? AppTheme.darkBorder : AppTheme.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color:
                        dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (satisfied)
            Icon(Icons.check_circle_rounded, color: color, size: 24)
          else
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: context.primary,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                l10n.isIndonesian ? 'Aktifkan' : 'Enable',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu kesiapan kunci kiosk (Lock Task Mode).
///
/// Status device owner TIDAK bisa diaktifkan dari dalam aplikasi — Android
/// hanya mengizinkan lewat provisioning (ADB/QR). Jadi kartu ini tidak
/// menawarkan tombol "Aktifkan", melainkan menampilkan langkah yang harus
/// dijalankan teknisi/guru supaya tidak ada harapan palsu.
class _KioskCard extends StatelessWidget {
  final KioskReadiness? kiosk;
  final bool dark;

  const _KioskCard({required this.kiosk, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = kiosk;
    final owner = k?.deviceOwner ?? false;
    final color = owner ? AppTheme.success : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: owner
              ? color.withValues(alpha: 0.35)
              : (dark ? AppTheme.darkBorder : AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  owner ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.isIndonesian
                          ? 'Kunci Kiosk Sejati'
                          : 'True Kiosk Lock',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: dark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      owner
                          ? (l10n.isIndonesian
                              ? 'HP siap: Home, Recents, dan panel notifikasi '
                                    'akan dimatikan selama ujian.'
                              : 'Device ready: Home, Recents, and the '
                                    'notification panel are disabled during the exam.')
                          : (l10n.isIndonesian
                              ? 'HP belum diprovision sebagai device owner. '
                                    'Tanpa ini siswa masih bisa keluar dari '
                                    'aplikasi.'
                              : 'Device is not provisioned as device owner. '
                                    'Without it, students can still leave the app.'),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: dark
                            ? AppTheme.darkTextMuted
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                owner
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: color,
                size: 24,
              ),
            ],
          ),
          if (owner && (k?.adminActive ?? false)) ...[
            const SizedBox(height: 10),
            Text(
              l10n.isIndonesian
                  ? 'Device admin aktif — penegakan tambahan siap.'
                  : 'Device admin active — extra enforcement ready.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color:
                    dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
          ],
          if (!owner) ...[
            const SizedBox(height: 12),
            _KioskProvisionHint(dark: dark),
          ],
        ],
      ),
    );
  }
}

/// Petunjuk provisioning device owner (tidak bisa dari dalam aplikasi).
class _KioskProvisionHint extends StatelessWidget {
  final bool dark;

  const _KioskProvisionHint({required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_rounded, size: 15, color: AppTheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.isIndonesian
                      ? 'Diperlukan aksi dari teknisi/guru'
                      : 'Requires technician/teacher action',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.isIndonesian
                ? 'Hubungkan HP ke komputer dengan USB debugging aktif, lalu '
                      'jalankan skrip di bawah dari folder frontend/android. '
                      'Buka ulang aplikasi setelah itu agar izin kiosk dikenali.'
                : 'Connect the phone to a computer with USB debugging enabled, '
                      'then run the script below from the frontend/android '
                      'folder. Relaunch the app afterwards so the kiosk '
                      'permission is recognized.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'tool/exam_device_owner.sh',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: dark ? AppTheme.accent : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistSummary extends StatelessWidget {
  final LockdownReadiness? ready;
  final bool dark;

  const _ChecklistSummary({
    required this.ready,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = ready;
    final items = <(String, bool)>[
      (
        l10n.isIndonesian
            ? 'Tidak ada aplikasi floating terdeteksi'
            : 'No floating app detected',
        r?.floatingAppsClean ?? false,
      ),
      (
        l10n.isIndonesian ? 'Izin overlay HiDocs' : 'HiDocs overlay permission',
        r?.overlayPermissionOk ?? false,
      ),
      (
        l10n.isIndonesian
            ? 'Kunci kiosk aktif (device owner)'
            : 'Kiosk lock ready (device owner)',
        r?.kiosk.deviceOwner ?? false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.isIndonesian ? 'Ringkasan Syarat' : 'Requirements Summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final (label, ok) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 17,
                    color: ok ? AppTheme.success : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ok
                            ? (dark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary)
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Text(
            l10n.isIndonesian
                ? 'Catatan: halaman ini hanya memeriksa perangkat (aplikasi '
                      'floating dan izin overlay). Bila sudah bersih, lanjutkan '
                      'ke langkah berikutnya untuk memasukkan token ujian.'
                : 'Note: this page only checks the device (floating apps and '
                      'overlay permission). Once clean, continue to the next '
                      'step to enter the exam token.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.isIndonesian
                ? 'Volume media akan otomatis dibuat 100% selama mengerjakan '
                      'ujian dan dikembalikan seperti semula saat keluar; '
                      'suara peringatan berbunyi jika Anda keluar aplikasi.'
                : 'Media volume is automatically set to 100% during the exam '
                      'and restored on exit; an alarm sounds if you leave the '
                      'app.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final bool isReady;
  final bool isEngaging;
  final VoidCallback onStart;
  final VoidCallback onRefresh;

  /// Teks tombol utama saat semua syarat terpenuhi — mengarah ke langkah
  /// berikutnya (layar token untuk tipe ujian, pengisian untuk survei).
  final String readyLabel;

  const _BottomAction({
    required this.isReady,
    required this.isEngaging,
    required this.onStart,
    required this.onRefresh,
    required this.readyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = context.isDark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? AppTheme.darkBorder : AppTheme.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              onPressed: isEngaging ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                l10n.isIndonesian ? 'Periksa Ulang' : 'Re-check',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: ElevatedButton.icon(
              onPressed: isReady && !isEngaging ? onStart : null,
              icon: isEngaging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded, size: 19),
              label: Text(
                isReady
                    ? readyLabel
                    : (l10n.isIndonesian
                        ? 'Syarat Belum Lengkap'
                        : 'Requirements Incomplete'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isReady ? AppTheme.success : Colors.grey.shade500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
