import 'package:flutter/material.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/screens/forms/fill_form_screen.dart';
import 'package:hi_docs/services/security/exam_lockdown_service.dart';
import 'package:hi_docs/services/security/exam_security_service.dart';
import 'package:hi_docs/utils/custom_page_route.dart';
import 'package:hi_docs/utils/theme_context.dart';

/// Gerbang wajib sebelum mengerjakan ujian.
///
/// Memeriksa dua proses screening yang terpisah + DND:
///  1. Daftar aplikasi floating yang terpasang (harus bersih).
///  2. Izin "tampil di atas aplikasi lain" untuk HiDocs.
///  3. Akses DND + DND aktif (sunyi total).
///
/// Selama belum semua terpenuhi, tombol "Mulai Ujian" terkunci.
class ExamLockdownGateScreen extends StatefulWidget {
  final FormModel form;
  final String preEnteredToken;
  final String responseId;

  const ExamLockdownGateScreen({
    required this.form,
    this.preEnteredToken = '',
    this.responseId = '',
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

  /// Form yang mewajibkan token harus punya sesi terdaftar supaya
  /// pengawasan (telemetry/autosave) benar-benar aktif.
  bool get _sessionReady =>
      !widget.form.hasExamToken || widget.responseId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> _startExam() async {
    final ready = _readiness;
    if (ready == null || !ready.isReady || !_sessionReady || _engaging) {
      return;
    }

    setState(() => _engaging = true);
    await ExamLockdownService.engage();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      CustomPageRoute(
        page: FillFormScreen(
          form: widget.form,
          preEnteredToken: widget.preEnteredToken,
          responseId: widget.responseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDark;
    final ready = _readiness;
    final isReady = (ready?.isReady ?? false) && _sessionReady;

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
                        ? 'Proses 1 — Screening Aplikasi'
                        : 'Step 1 — App Screening',
                    subtitle: l10n.isIndonesian
                        ? 'Semua aplikasi floating/bubble harus ditutup atau dihapus.'
                        : 'All floating/bubble apps must be closed or removed.',
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
                        ? 'Proses 3 — Jangan Ganggu (DND)'
                        : 'Step 3 — Do Not Disturb',
                    subtitle: l10n.isIndonesian
                        ? 'Notifikasi, telepon, dan distraksi lain diblokir selama ujian.'
                        : 'Notifications, calls, and distractions are blocked during the exam.',
                  ),
                  const SizedBox(height: 10),
                  _RequirementCard(
                    icon: Icons.do_not_disturb_on_rounded,
                    title: l10n.isIndonesian
                        ? 'Akses Kebijakan Notifikasi'
                        : 'Notification Policy Access',
                    description: l10n.isIndonesian
                        ? 'Izinkan HiDocs mengaktifkan mode sunyi total.'
                        : 'Allow HiDocs to enable total silence mode.',
                    satisfied: ready?.dndAccessOk ?? false,
                    dark: isDark,
                    onAction: () => ExamSecurityService.openDndAccessSettings(),
                  ),
                  const SizedBox(height: 10),
                  _RequirementCard(
                    icon: Icons.volume_off_rounded,
                    title: l10n.isIndonesian
                        ? 'Mode Sunyi Total Aktif'
                        : 'Total Silence Active',
                    description: l10n.isIndonesian
                        ? 'Harus aktif. Telepon & notifikasi akan diblokir sampai ujian selesai.'
                        : 'Must be on. Calls & notifications blocked until the exam ends.',
                    satisfied: ready?.dndActive ?? false,
                    dark: isDark,
                    onAction: () async {
                      await ExamSecurityService.enableTotalSilence();
                      await _refresh();
                    },
                  ),
                  const SizedBox(height: 24),

                  _ChecklistSummary(
                    ready: ready,
                    dark: isDark,
                    sessionReady: _sessionReady,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _BottomAction(
        isReady: isReady,
        isEngaging: _engaging,
        onStart: _startExam,
        onRefresh: _refresh,
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
        _stepDot(1, done: true),
        _stepLine(),
        _stepDot(2, active: true),
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
            ? 'Pemeriksaan tidak didukung di perangkat ini'
            : 'Screening not supported on this device',
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
              ? 'Tidak ada aplikasi floating terdeteksi.'
              : 'No floating apps detected.',
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
                      ? '${data.suspicious.length} aplikasi terdeteksi'
                      : '${data.suspicious.length} apps detected',
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
                ? 'Tutup aplikasi berikut (matikan bubble/fenster mengambang) lalu periksa ulang.'
                : 'Close the following apps (turn off bubbles/floating windows) then re-check.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...data.suspicious.take(20).map(
                (app) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: app.riskLevel >= 3
                              ? AppTheme.error
                              : AppTheme.warning,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          app.appName.isEmpty
                              ? app.packageName
                              : '${app.appName} · ${app.packageName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (data.suspicious.length > 20)
            Text(
              l10n.isIndonesian
                  ? '+${data.suspicious.length - 20} aplikasi lainnya...'
                  : '+${data.suspicious.length - 20} more apps...',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textMuted,
              ),
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                for (final line in lines) ...[
                  const SizedBox(height: 4),
                  Text(
                    line,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted,
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

class _ChecklistSummary extends StatelessWidget {
  final LockdownReadiness? ready;
  final bool dark;
  final bool sessionReady;

  const _ChecklistSummary({
    required this.ready,
    required this.dark,
    required this.sessionReady,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = ready;
    final items = <(String, bool)>[
      (
        l10n.isIndonesian ? 'Aplikasi floating bersih' : 'Floating apps clean',
        r?.floatingAppsClean ?? false,
      ),
      (
        l10n.isIndonesian ? 'Izin overlay HiDocs' : 'HiDocs overlay permission',
        r?.overlayPermissionOk ?? false,
      ),
      (
        l10n.isIndonesian ? 'Akses DND' : 'DND access',
        r?.dndAccessOk ?? false,
      ),
      (
        l10n.isIndonesian ? 'Sunyi total aktif' : 'Total silence active',
        r?.dndActive ?? false,
      ),
      (
        l10n.isIndonesian
            ? 'Sesi ujian terdaftar'
            : 'Exam session registered',
        sessionReady,
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

  const _BottomAction({
    required this.isReady,
    required this.isEngaging,
    required this.onStart,
    required this.onRefresh,
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
          OutlinedButton.icon(
            onPressed: isEngaging ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.isIndonesian ? 'Periksa Ulang' : 'Re-check'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                    ? (l10n.isIndonesian ? 'Mulai Ujian' : 'Start Exam')
                    : (l10n.isIndonesian
                        ? 'Syarat Belum Lengkap'
                        : 'Requirements Incomplete'),
                style: const TextStyle(
                  fontSize: 14.5,
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
