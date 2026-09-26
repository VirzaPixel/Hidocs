import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/screens/forms/fill_form_screen.dart';
import 'package:hi_docs/services/api/api_client.dart';
import 'package:hi_docs/services/security/exam_lockdown_service.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class ExamTokenScreen extends StatefulWidget {
  final FormModel form;

  const ExamTokenScreen({required this.form, super.key});

  @override
  State<ExamTokenScreen> createState() => _ExamTokenScreenState();
}

class _ExamTokenScreenState extends State<ExamTokenScreen> {
  final _tokenCtrl = TextEditingController();
  bool _error = false;
  bool _isChecking = false;
  int _attempts = 0;
  String _enteredToken = '';

  String _responseId = '';

  /// Token ujian memakai field `examToken` (bukan accessToken form QR-only).
  /// Form bertoken ujian (`is_token_protected`) wajib mengisi token di sini.
  bool get _formHasToken =>
      widget.form.hasExamToken || widget.form.isTokenProtected;

  @override
  void initState() {
    super.initState();

    // Halaman masukan token BUKAN bagian dari sesi ujian. Semua fitur
    // "kunci" (alarm keluar, volume penuh, FLAG_SECURE, layar penuh)
    // baru boleh aktif di [FillFormScreen]. Pemanggilan ini juga
    // membersihkan sisa penguncian dari percobaan sebelumnya, sehingga
    // menutup aplikasi di halaman ini benar-benar SUNYI — tidak ada
    // suara alarm.
    ExamLockdownService.ensureIdle();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  /// Kode uuid nol. Backend mengirim ini saat sesi belum dibuat — misalnya
  /// pengguna belum login sehingga `respondent_email` kosong. Nilai ini BUKAN
  /// sesi yang sah, jadi diperlakukan sebagai "tidak ada response id".
  static const String _zeroUuid = '00000000-0000-0000-0000-000000000000';

  static String _cleanSessionId(Object? value) {
    final id = (value ?? '').toString().trim();
    return id == _zeroUuid ? '' : id;
  }

  /// Lanjut ke pengisian soal dengan membawa token + response id sesi ujian.
  void _proceed() {
    Navigator.pushReplacement(
      context,
      CustomPageRoute(
        page: FillFormScreen(
          form: widget.form,
          preEnteredToken: _enteredToken,
          responseId: _responseId,
        ),
      ),
    );
  }

  Future<void> _verify() async {
    if (_isChecking) return;

    final input = _tokenCtrl.text.trim();
    final hasToken = _formHasToken;

    if (hasToken && input.isEmpty) {
      setState(() => _error = true);
      return;
    }

    setState(() {
      _isChecking = true;
      _error = false;
    });

    // Selalu hubungi `verify-token`: di sinilah server mencatat sesi ujian
    // (mengembalikan `response_id`) yang dipakai autosave, telemetry
    // pelanggaran, dan pantauan pengawas.
    try {
      final data = await ApiClient.post(
        '/public/forms/${Uri.encodeComponent(widget.form.slug)}/verify-token',
        body: {
          'token': input,
          'respondent_email': _respondentEmail(),
        },
      );
      if (!mounted) return;

      if (data is Map) {
        _enteredToken = input;
        _responseId = _cleanSessionId(data['response_id']);
        if (_responseId.isEmpty && data['session_state'] is Map) {
          _responseId =
              _cleanSessionId(data['session_state']['response_id']);
        }
        final st = (data['session_token'] ?? '').toString();
        if (st.isNotEmpty) ApiClient.examSessionToken = st;
        _proceed();
        return;
      }

      _failVerification();
    } catch (_) {
      if (!mounted) return;

      // Form tanpa token ujian: jangan mengunci siswa hanya karena pencatatan
      // sesi gagal (mis. jaringan) — token bukan syarat untuk form ini.
      if (!hasToken) {
        _proceed();
        return;
      }

      _failVerification();
    }
  }

  void _failVerification() {
    setState(() {
      _isChecking = false;
      _error = true;
      _attempts++;
    });
  }

  /// Batal / kembali dari layar token.
  ///
  /// Tidak perlu melepas penguncian apa pun: halaman-gerbang tidak lagi
  /// menyalakan volume/alarm, dan [FillFormScreen] yang-radio-aktif selama
  /// penguncian itu tidak pernah dibangun sampai token diterima.
  void _exit() {
    Navigator.pop(context);
  }

  String _respondentEmail() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.currentUser?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(l10n.enterToken),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _exit,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _StepIndicator(current: 2, total: 2, dark: isDark),
            const SizedBox(height: 16),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.primary, context.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryWith(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Icon(Icons.vpn_key_rounded,
                  size: 42, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              widget.form.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Badge token hanya muncul bila form memang menuntut token.
            if (_formHasToken)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.vpn_key_rounded,
                        size: 15, color: AppTheme.warning),
                    const SizedBox(width: 6),
                    Text(
                      l10n.whichToken,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formHasToken
                        ? l10n.authTokenTitle
                        : (l10n.isIndonesian
                            ? 'Konfirmasi Masuk Ujian'
                            : 'Exam Entry Confirmation'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formHasToken
                        ? l10n.askTokenFrom
                        : (l10n.isIndonesian
                            ? 'Form ini tidak memerlukan token. Tekan '
                                '"Lanjutkan" untuk mulai mengerjakan soal.'
                            : 'This form has no token. Press "Continue" to '
                                'start answering.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenCtrl,
                    // Token ujian selalu KAPITAL (seperti kebanyakan kode
                    // ujian yang dibagikan guru).
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const <TextInputFormatter>[
                      UpperCaseTokenFormatter(),
                    ],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.enterToken,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.textMuted,
                      ),
                      errorText: _error
                          ? l10n.wrongToken +
                              (_attempts >= 3 ? l10n.tokenEnsureCorrect : '')
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                    ),
                    onChanged: (_) {
                      if (_error) setState(() => _error = false);
                    },
                    onFieldSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(Icons.login_rounded, size: 20),
                      label: Text(
                        _isChecking ? l10n.checking : l10n.continueAction,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _exit,
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  final bool dark;

  const _StepIndicator(
      {required this.current, required this.total, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final step = i + 1;
        final active = step == current;
        final done = step < current;
        final color = done || active ? AppTheme.success : AppTheme.textMuted;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(color: color),
              ),
              child: Center(
                child: done
                    ? Icon(Icons.check_rounded, size: 14, color: color)
                    : Text(
                        '$step',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
              ),
            ),
            if (step < total)
              Container(
                width: 28,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: AppTheme.textMuted.withValues(alpha: 0.35),
              ),
          ],
        );
      }),
    );
  }
}

/// Memaksa setiap karakter yang diketik/tempel menjadi huruf kapital,
/// sehingga token ujian selalu dalam bentuk yang dikenali backend.
class UpperCaseTokenFormatter extends TextInputFormatter {
  const UpperCaseTokenFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
    );
  }
}

