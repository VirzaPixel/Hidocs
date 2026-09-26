import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/services/security/question_image_renderer.dart';
import 'package:hi_docs/widgets/form/form_theme.dart';
import 'package:hi_docs/widgets/common/gradient_button.dart';
import 'package:hi_docs/widgets/exam/math_formula_widget.dart';
import 'package:hi_docs/widgets/exam/code_block_widget.dart';
import 'package:hi_docs/widgets/exam/image_zoom_widget.dart';
import 'package:hi_docs/widgets/common/timer_widget.dart';
import 'package:hi_docs/widgets/exam/audio_player_widget.dart';
import 'package:hi_docs/widgets/form/rich_text_view.dart';
import 'package:hi_docs/widgets/exam/secure_question_canvas.dart';
import 'package:hi_docs/services/api/api_client.dart';
import 'package:hi_docs/services/security/exam_lockdown_service.dart';
import 'package:hi_docs/services/security/exam_security_service.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/utils/custom_page_route.dart';
import 'package:hi_docs/utils/submit_payload.dart';

class FillFormScreen extends StatefulWidget {
  final FormModel form;
  final String preEnteredToken;

  /// Id respons aktif dari backend (dipakai untuk autosave & telemetry ujian).
  /// Bisa kosong bila backend belum mengembalikannya; dalam hal itu fitur
  /// pengawasan akan dinonaktifkan secara aman.
  final String responseId;

  const FillFormScreen({
    required this.form,
    this.preEnteredToken = '',
    this.responseId = '',
    super.key,
  });

  @override
  State<FillFormScreen> createState() => _FillFormScreenState();
}

class _FillFormScreenState extends State<FillFormScreen>
    with WidgetsBindingObserver {
  late List<QuestionModel> _questions;

  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _controllers = {};
  final Set<int> _flags = {};

  late String _token;

  Timer? _timer;

  int _remaining = 0;
  int _current = 0;

  bool _submitted = false;
  bool _isSubmitting = false;

  // --- Pengawasan ujian ---
  String? _responseId;
  bool _overlayWarningVisible = false;
  String _overlayWarningText = '';
  int _violationCount = 0;

  /// `true` selama aplikasi sedang berada di luar foreground dalam SATU
  /// episode. Mencegah satu kali keluar dihitung beberapa kali.
  bool _exitEpisode = false;

  Timer? _autosaveTimer;
  bool _accessRevoked = false;
  final Set<String> _dirtyQuestions = {};
  final Set<String> _unsavedQuestions = {};
  bool get _hasUnsaved => _unsavedQuestions.isNotEmpty;

  bool get _examMode => widget.form.isExam;

  final ScrollController _numberStripController = ScrollController();

  /// Bunyikan alarm keluar lewat native (assets/keluar.mp3).
  ///
  /// Sengaja bukan audioplayers: saat siswa keluar aplikasi, engine Flutter
  /// bisa sempat dijeda sehingga suaranya tidak pernah keluar. Native
  /// MediaPlayer (USAGE_ALARM) tetap berbunyi dan tidak terpengaruh volume
  /// media yang di-mute.
  void _soundExitAlarm() {
    ExamSecurityService.playExitAlarm();
  }

  @override
  void initState() {
    super.initState();

    _questions = List<QuestionModel>.from(
      widget.form.questions,
    );

    _token = widget.preEnteredToken.isNotEmpty
        ? widget.preEnteredToken
        : widget.form.accessToken;

    _responseId = widget.responseId.isNotEmpty ? widget.responseId : null;

    // Status bar HP disembunyikan selama mengisi. Dua lapis dipakai bersama:
    //  1. `immersiveSticky` dari Flutter — CATATAN PENTING: pada targetSdk 36
    //     (nilai proyek ini) Flutter memaksa `edgeToEdge` dan mengabaikan mode
    //     ini, jadi ia hanya berfungsi sebagai cadangan untuk targetSdk lama;
    //  2. kunci native `setFullscreenLock` (WindowInsetsControllerCompat) —
    //     INILAH yang benar-benar bekerja di perangkat: bar disembunyikan
    //     dengan BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE (hanya muncul sesaat,
    //     overlay tidak interaktif) plus watchdog yang menutup ulang bar.
    // Informasinya — jam + baterai — disediakan aplikasi sendiri lewat
    // [_DeviceStatusBar].
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    ExamSecurityService.setFullscreenLock(true);

    if (_examMode) {
      WidgetsBinding.instance.addObserver(this);

      ExamViolationReporter.register(_handleReportedViolation);

      ExamLockdownService.engage();

      _autosaveTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _flushAutosave(),
      );

      // CATATAN (Revisi Lanjutan 9): skoring aplikasi floating SETELAH
      // ujian dimulai DIHAPUS. Deteksi floating hanya dijalankan sekali di
      // halaman "Persiapan Ujian" (screening penuh). Selama mengerjakan,
      // aplikasi tidak boleh memunculkan notifikasi floating — free-riding
      // pada sinyal yang salah membuat '=' deteksi hantu' dan nama baik
      // aplikasi rusak.
      _restoreExamSession();
    }

    QuestionImageRenderer.warmup().then((_) {
      if (mounted) setState(() {});
    });

    if (widget.form.shuffleQuestions) {
      _questions.shuffle();
    }

    if (widget.form.shuffleOptions) {
      _questions = _questions.map((q) {
        if ((q.type == QuestionType.multipleChoice ||
                q.type == QuestionType.checkbox ||
                q.type == QuestionType.imageChoice) &&
            q.options.isNotEmpty) {
          final shuffledOptions =
              List<OptionModel>.from(q.options);

          shuffledOptions.shuffle();

          return q.copyWith(options: shuffledOptions);
        }

        return q;
      }).toList();
    }

    if (widget.form.hasTimer) {
      _remaining = widget.form.timerMinutes * 60;

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted || _submitted) return;

          if (_remaining <= 1) {
            _timer?.cancel();
            _remaining = 0;
            _autoSubmit();
          } else {
            setState(() {
              _remaining--;
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    // Kembalikan status bar sistem seperti semula saat meninggalkan halaman.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ExamSecurityService.setFullscreenLock(false);

    if (_examMode) {
      _autosaveTimer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
      ExamViolationReporter.unregister();
      ExamLockdownService.release();
    }

    _numberStripController.dispose();

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // -----------------------------------------------------------------
  // Pengawasan ujian: lifecycle, telemetry, overlay, autosave
  // -----------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_examMode) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Android mengirim `inactive` → `hidden` → `paused` untuk SATU kali
        // keluar aplikasi. Tanpa [_exitEpisode] ketiganya terhitung sebagai
        // tiga pelanggaran terpisah sehingga satu keluar saja langsung
        // mencabut akses ujian. [_exitEpisode] memastikan satu episode keluar
        // = satu pelanggaran, dan direset begitu aplikasi kembali aktif.
        if (_exitEpisode) return;
        _exitEpisode = true;

        // Alarm keluar tetap berbunyi walau hook platform tidak sempat
        // terpanggil (native juga memicunya sendiri dari onPause).
        _soundExitAlarm();
        _registerExitViolation(state);
        break;

      case AppLifecycleState.resumed:
        // Episodenya sudah selesai — hitungan berikutnya kembali dari nol.
        _exitEpisode = false;
        // Kunci native sudah dipasang, tapi saat app dijeda sistem bisa
        // melepas status bar. Pastikan immersive + kunci native aktif lagi
        // setiap kali app kembali ke depan.
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        ExamSecurityService.setFullscreenLock(true);
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  /// Catat satu pelanggaran "keluar aplikasi" lalu tampilkan peringatannya.
  Future<void> _registerExitViolation(AppLifecycleState state) async {
    if (_accessRevoked || _submitted) return;

    _violationCount++;
    _reportViolation(
      'APP_BACKGROUNDED',
      message: 'Aplikasi ujian ditinggalkan (state: $state). '
          'Pelanggaran ke-$_violationCount dari $kMaxExitViolations.',
    );

    if (_violationCount >= kMaxExitViolations) {
      await _revokeAndSubmit();
      return;
    }
    if (!mounted) return;
    final remaining = kMaxExitViolations - _violationCount;
    setState(() {
      _overlayWarningVisible = true;
      _overlayWarningText =
          'Anda terdeteksi keluar dari aplikasi ujian.\n'
          'Pelanggaran ke-$_violationCount dari $kMaxExitViolations. '
          'Sisa $remaining kesempatan lagi, setelah itu akses ujian akan dibatalkan.';
    });
  }

  /// Revoke akses dan submit otomatis karena pelanggaran melebihi batas.
  Future<void> _revokeAndSubmit() async {
    if (_accessRevoked || _submitted) return;

    // Beritahu backend dan kirim telemetry.
    final rid = _responseId;
    if (rid != null && rid.isNotEmpty) {
      ExamLockdownService.revokeAccess(
        rid,
        violationCount: _violationCount,
      );
    }

    _timer?.cancel();
    _autosaveTimer?.cancel();

    if (mounted) {
      setState(() {
        _accessRevoked = true;
        _overlayWarningVisible = false;
      });
    }
  }

  /// Jembatan hook dari [ExamViolationReporter] menuju [_reportViolation].
  Future<void> _handleReportedViolation(
    String responseId,
    String eventType,
    String? message,
    int questionIndex,
  ) async {
    await ApiClient.sendTelemetry(
      responseId: responseId,
      eventType: eventType,
      eventMessage: message,
      currentQuestionIndex: questionIndex,
    );
  }

  /// Kirim satu event pelanggaran bila respons sudah punya id.
  void _reportViolation(String eventType, {String? message}) {
    final rid = _responseId;
    if (rid == null || rid.isEmpty) return;

    ExamLockdownService.reportViolation(
      rid,
      eventType: eventType,
      message: message,
      questionIndex: _current,
    );
  }

  Future<void> _acknowledgeWarning() async {
    final rid = _responseId;
    if (rid != null && rid.isNotEmpty) {
      await ApiClient.acknowledgeWarning(rid);
    }
    if (!mounted) return;
    setState(() {
      _overlayWarningVisible = false;
    });
  }

  Future<void> _restoreExamSession() async {
    final rid = _responseId;
    if (rid == null || rid.isEmpty) return;
    await _loadAutosaveQueue();
    final session = await ApiClient.getExamSession(rid);
    if (!mounted || session == null) return;
    final questions = session['questions'];
    if (questions is! List) return;
    setState(() {
      for (final item in questions.whereType<Map>()) {
        final qid = (item['question_id'] ?? '').toString();
        if (qid.isEmpty) continue;
        final idx = _questions.indexWhere((q) => q.id == qid);
        if (idx < 0) continue;
        if (item['is_flagged'] == true) _flags.add(idx);
        if (item['is_answered'] != true) continue;
        final q = _questions[idx];
        final sel = item['selected_option_id'];
        if (sel != null && sel.toString().isNotEmpty) {
          _answers[qid] = sel.toString();
          continue;
        }
        final text = (item['answer_text'] ?? '').toString();
        if (q.type == QuestionType.matching) {
          final pairs = item['match_pairs'];
          if (pairs is List && pairs.isNotEmpty) {
            _answers[qid] = {
              for (final p in pairs.whereType<Map>())
                (p['match_key'] ?? '').toString():
                    (p['match_target_text'] ?? '').toString(),
            };
          } else if (text.isNotEmpty) {
            try {
              final decoded = jsonDecode(text);
              if (decoded is Map) {
                _answers[qid] = Map<String, String>.from(decoded.map(
                    (k, v) => MapEntry(k.toString(), v.toString())));
              }
            } catch (_) {}
          }
          continue;
        }
        if (q.type == QuestionType.checkbox && text.isNotEmpty) {
          _answers[qid] =
              text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
          continue;
        }
        if (q.type == QuestionType.rating) {
          final n = int.tryParse(text);
          if (n != null && n != 0) _answers[qid] = n;
          continue;
        }
        if (text.isNotEmpty) _answers[qid] = text;
      }
      final order = (session['current_question_index'] as num?)?.toInt();
      if (order != null && order >= 1 && order <= _questions.length) {
        _current = order - 1;
      }
      final started = DateTime.tryParse(session['started_at']?.toString() ?? '');
      final dur = (session['duration_minutes'] as num?)?.toInt() ??
          widget.form.timerMinutes;
      if (widget.form.hasTimer && started != null && dur > 0) {
        final elapsed = DateTime.now().difference(started).inSeconds;
        _remaining = (dur * 60 - elapsed).clamp(0, dur * 60);
      }
    });
  }

  /// Kirim semua jawaban yang berubah untuk soal yang ditandai dirty.
  /// Gagal kirim → masuk antrean `_unsavedQuestions` (badge tampil + persist).
  Future<void> _flushAutosave() async {
    if (!_examMode) return;
    final rid = _responseId;
    if (rid == null || rid.isEmpty) return;
    if (_dirtyQuestions.isEmpty && _unsavedQuestions.isEmpty) return;

    final pending = <String>{
      ..._dirtyQuestions,
      ..._unsavedQuestions,
    };
    _dirtyQuestions.clear();

    for (final qid in pending) {
      final ok = await _autosaveQuestion(qid);
      if (!mounted) return;
      setState(() {
        if (ok) {
          _unsavedQuestions.remove(qid);
        } else {
          _unsavedQuestions.add(qid);
        }
      });
    }
    await _persistAutosaveQueue();
  }

  String get _autosaveQueueKey => 'autosave_queue_${_responseId ?? 'noresp'}';

  Future<void> _persistAutosaveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _autosaveQueueKey, _unsavedQuestions.toList());
    } catch (_) {}
  }

  Future<void> _loadAutosaveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_autosaveQueueKey) ?? [];
      if (!mounted || stored.isEmpty) return;
      setState(() => _unsavedQuestions.addAll(stored));
    } catch (_) {}
  }

  /// Simpan satu jawaban soal ke backend (dipakai autosave & flag).
  /// Return true bila tersimpan.
  Future<bool> _autosaveQuestion(String questionId) async {
    if (!_examMode) return true;
    final rid = _responseId;
    if (rid == null || rid.isEmpty) return false;

    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index < 0) return true;
    final q = _questions[index];
    final value = _answers[questionId];

    String? selectedOptionId;
    String answerText = '';
    List<Map<String, dynamic>>? matchPairs;

    if (q.type == QuestionType.multipleChoice ||
        q.type == QuestionType.imageChoice ||
        q.type == QuestionType.yesNo) {
      selectedOptionId = value?.toString();
    } else if (q.type == QuestionType.checkbox) {
      answerText = value is Set ? value.join(',') : '';
    } else if (q.type == QuestionType.matching) {
      if (value is Map) {
        matchPairs = value.entries
            .map((e) => {
                  'match_key': e.key.toString(),
                  'match_target_text': e.value.toString(),
                })
            .toList();
      }
      answerText = jsonEncode(value ?? {});
    } else {
      answerText = value?.toString() ?? '';
    }

    final ok = await ApiClient.autosaveAnswer(
      responseId: rid,
      questionId: questionId,
      selectedOptionId: selectedOptionId,
      answerText: answerText,
      isFlagged: _flags.contains(index),
      matchPairs: matchPairs,
    );
    return ok;
  }

  TextEditingController _getController(
    String questionId,
  ) {
    if (!_controllers.containsKey(questionId)) {
      _controllers[questionId] = TextEditingController(
        text: _answers[questionId]?.toString() ?? '',
      );
    }

    return _controllers[questionId]!;
  }

  /// Tampilkan kegagalan pengiriman sebagai ALERT yang benar-benar terbaca.
  ///
  /// Sebelumnya kegagalan hanya muncul sebagai SnackBar sekejap. Pesannya
  /// sering generik ("Invalid request payload") dan hilang sebelum sempat
  /// dibaca, sehingga pengguna merasa aplikasinya rusak tanpa tahu penyebab
  /// atau apa yang harus dilakukan. Dialog ini bertahan sampai ditutup dan
  /// menyediakan tombol "Salin pesan" agar isinya bisa dilaporkan ke pengawas.
  void _showSubmitError(String message) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.isIndonesian
                      ? 'Pengiriman jawaban gagal. Baca penjelasannya.'
                      : 'Submitting answers failed. See the explanation.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.error_outline_rounded,
          color: AppTheme.error,
          size: 36,
        ),
        title: Text(
          l10n.isIndonesian
              ? 'Jawaban gagal dikirim'
              : 'Answers could not be sent',
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.isIndonesian
                        ? 'Pesan galat disalin.'
                        : 'Error message copied.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(l10n.isIndonesian ? 'Salin pesan' : 'Copy message'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.isIndonesian ? 'Coba lagi' : 'Try again'),
          ),
        ],
      ),
    );
  }

  void _autoSubmit() {
    if (_submitted || _isSubmitting) return;

    _submitForm(
      auto: true,
    );
  }

  Future<void> _submitForm({
    bool auto = false,
  }) async {
    if (_submitted || _isSubmitting) return;

    final l10n = AppLocalizations.of(context);

    if (!auto) {
      final unanswered = _questions.where(
        (question) {
          if (!question.isRequired) {
            return false;
          }

          final answer = _answers[question.id];

          if (answer == null) {
            return true;
          }

          if (answer is String &&
              answer.trim().isEmpty) {
            return true;
          }

          if (answer is int && answer == 0) {
            return true;
          }

          if (question.type == QuestionType.matching && answer is Map) {
            return answer.values.any((v) => v.toString().trim().isEmpty);
          }

          if (question.type == QuestionType.checkbox && answer is Set) {
            return (answer).isEmpty;
          }

          return false;
        },
      ).toList();

      if (unanswered.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.answerRequired,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        return;
      }
    }

    // --- Penjaga payload: sebab "Invalid request payload" yang paling sering ---
    //
    // Backend mem-binding `respondent_email` sebagai `required,email`, jadi
    // permintaan TANPA email selalu dibalas `400 "Invalid request payload"`.
    // Ini bisa terjadi bila siswa membuka form lewat QR/tautan dalam keadaan
    // belum login (rute `/scan-form`, `/link-input`, dan deep-link `/f/<slug>`
    // tidak dijaga login). Lebih baik dicegah di sini dengan pesan yang jelas
    // daripada membiarkan server menolak dengan kalimat buntu.
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final respondentEmail = auth.currentUser?.email.trim() ?? '';

    if (respondentEmail.isEmpty) {
      _showSubmitError(
        l10n.isIndonesian
            ? 'Jawaban tidak dikirim: Anda belum masuk, sehingga server tidak '
                  'tahu siapa pengirimnya. Masuk (login) dulu dengan akun yang '
                  'punya email, lalu tekan Kirim Jawaban kembali. Jawaban Anda '
                  'saat ini masih tersimpan di perangkat ini.'
            : 'Answers were not sent: you are not signed in, so the server '
                  'cannot identify the respondent. Sign in first, then submit '
                  'again. Your current answers are still kept on this device.',
      );
      return;
    }

    _timer?.cancel();

    setState(() {
      _isSubmitting = true;
    });

    final formProvider = Provider.of<FormProvider>(
      context,
      listen: false,
    );

    final responseProvider = Provider.of<ResponseProvider>(
      context,
      listen: false,
    );

    final answers = <Map<String, dynamic>>[];

    for (final q in _questions) {
      final value = _answers[q.id];

      if (value == null) {
        continue;
      }

      if (value is String && value.trim().isEmpty) {
        continue;
      }

      if (q.type == QuestionType.multipleChoice ||
          q.type == QuestionType.imageChoice ||
          q.type == QuestionType.yesNo) {
        answers.add({
          'question_id': q.id,
          'selected_option_id': value,
          'answer_text': null,
        });
      } else if (q.type == QuestionType.checkbox) {
        final selectedIds = value is Set
            ? value.map((e) => e.toString()).toSet().toList()
            : <String>[];
        for (final optId in selectedIds) {
          answers.add({
            'question_id': q.id,
            'selected_option_id': optId,
            'answer_text': null,
          });
        }
      } else if (q.type == QuestionType.matching) {
        final matchMap = value is Map
            ? Map<String, String>.from(
                value.map((k, v) => MapEntry(k.toString(), v.toString())),
              )
            : <String, String>{};
        final encoded = jsonEncode(matchMap);
        final pairs = matchMap.entries
            .map((e) => {
                  'match_key': e.key,
                  'match_target_text': e.value,
                })
            .toList();
        answers.add({
          'question_id': q.id,
          'selected_option_id': null,
          'answer_text': encoded,
          'match_pairs': pairs,
        });
      } else {
        answers.add({
          'question_id': q.id,
          'selected_option_id': null,
          'answer_text': value.toString(),
        });
      }
    }

    // Buang baris yang tidak mungkin diterima backend SEBELUM dikirim.
    // Satu `question_id` non-UUID membuat `ShouldBindJSON` menolak SELURUH
    // body dengan `400 "Invalid request payload"`, sehingga seluruh jawaban
    // ikut hilang. Lihat [sanitizeSubmitAnswers].
    final safeAnswers = sanitizeSubmitAnswers(answers);

    final result = await formProvider.submitForm(
      widget.form.id,
      respondentEmail: respondentEmail,
      answers: safeAnswers,
      auto: auto,
      token: _token,
      responseId: _responseId ?? '',
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      final errorMessage = formProvider.error ?? l10n.failSendResp;

      formProvider.clearError();

      setState(() {
        _isSubmitting = false;
      });

      _showSubmitError(errorMessage);

      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });

    if (_examMode) {
      _autosaveTimer?.cancel();
      final submittedId = (result['response_id'] ?? '').toString();
      if (submittedId.isNotEmpty) {
        _responseId = submittedId;
      }
      _unsavedQuestions.clear();
      _dirtyQuestions.clear();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_autosaveQueueKey);
      } catch (_) {}
    }

    responseProvider.recordSubmission(
      formId: widget.form.id,
      formTitle: widget.form.title,
      responseId: (result['response_id'] ?? '').toString(),
      respondentId: auth.currentUser?.id ?? '',
      respondentEmail: respondentEmail,
      answers: Map<String, dynamic>.from(_answers),
      totalScore: (result['total_score'] as num?)?.toDouble(),
      submittedAt:
          DateTime.tryParse(result['submitted_at']?.toString() ?? ''),
      maxScore: widget.form.maxScore,
    );

    if (auto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.timer_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.timeUpAutoSubmit,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _scrollToStrip(int index) {
    if (!_numberStripController.hasClients) return;
    final targetOffset = (index * 44.0) - 100.0;
    _numberStripController.animateTo(
      targetOffset.clamp(0.0, _numberStripController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _nextQuestion() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
      });
      _scrollToStrip(_current);
    }
  }

  void _previousQuestion() {
    if (_current > 0) {
      setState(() {
        _current--;
      });
      _scrollToStrip(_current);
    }
  }

  void _jumpToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      setState(() => _current = index);
      _scrollToStrip(_current);
    }
  }

  bool _isAnswered(int index) {
    if (index < 0 || index >= _questions.length) return false;
    final q = _questions[index];
    final answer = _answers[q.id];
    if (answer == null) return false;
    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is int) return answer != 0;
    if (answer is Set) return answer.isNotEmpty;
    if (answer is Map) return answer.values.any((v) => v.toString().trim().isNotEmpty);
    return answer.toString().trim().isNotEmpty;
  }

  void _toggleFlag(int i) {
    setState(() {
      if (!_flags.add(i)) {
        _flags.remove(i);
      }
    });

    if (_examMode && i >= 0 && i < _questions.length) {
      final qid = _questions[i].id;
      _dirtyQuestions.add(qid);
      _autosaveQuestion(qid);
    }
  }

  void _showQuestionPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkCard
              : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final mutedColor =
            isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
        final answeredCount = _questions
            .where((q) => _isAnswered(_questions.indexOf(q)))
            .length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.questionNo,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LegendDot(
                    current: true,
                    color: ctx.primary,
                    label: l10n.navLegendCurrent,
                  ),
                  _LegendDot(
                    color: AppTheme.success,
                    label: l10n.navLegendAnswered,
                  ),
                  _LegendDot(
                    color: AppTheme.warning,
                    label: l10n.navLegendFlagged,
                  ),
                  _LegendDot(
                    outlined: true,
                    color: mutedColor,
                    label: l10n.navLegendUnanswered,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_questions.length, (i) {
                      final isCurrent = i == _current;
                      final isFlaggedQ = _flags.contains(i);
                      final isAnswered = _isAnswered(i);

                      Color bg;
                      Color fg;
                      Color borderC;
                      if (isCurrent) {
                        bg = ctx.primary;
                        fg = Colors.white;
                        borderC = ctx.primary;
                      } else if (isFlaggedQ) {
                        bg = AppTheme.warning.withValues(alpha: 0.15);
                        fg = AppTheme.warning;
                        borderC = AppTheme.warning.withValues(alpha: 0.40);
                      } else if (isAnswered) {
                        bg = AppTheme.success.withValues(alpha: 0.12);
                        fg = AppTheme.success;
                        borderC = AppTheme.success.withValues(alpha: 0.30);
                      } else {
                        bg = isDark
                            ? AppTheme.darkSurface
                            : AppTheme.surfaceLight;
                        fg = mutedColor;
                        borderC = isDark ? AppTheme.darkBorder : AppTheme.border;
                      }

                      return GestureDetector(
                        onTap: () {
                          _jumpToQuestion(i);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bg,
                            border: Border.all(
                              color: borderC,
                              width: isCurrent ? 2.5 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: fg,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryLine(
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.success,
                      text: l10n.answeredSummary(answeredCount),
                    ),
                    _SummaryLine(
                      icon: Icons.flag_rounded,
                      color: AppTheme.warning,
                      text: l10n.flaggedSummary(_flags.length),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_questions.isEmpty) {
      // Auto-navigate back after build completes since there's nothing to fill
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.form.title),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.noQuestionsYetF,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (_submitted) {
      return _SuccessScreen(
        onBack: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (_) => false,
        ),
      );
    }

    if (_accessRevoked) {
      return _RevokedScreen(
        onBack: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (_) => false,
        ),
      );
    }

    final q = _questions[_current];

    final questionImagePath = QuestionImageRenderer.pathFor(q);

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final isWarn =
        widget.form.hasTimer &&
        _remaining < 60;

    return PopScope(
      canPop: !_examMode && !_isSubmitting, // Jika mode ujian, cegah pop sembarangan.
      onPopInvokedWithResult: (didPop, dynamic _) async {
        if (didPop) return;

        if (_examMode) {
          // BUNYIKAN ALARM KELUAR (assets/keluar.mp3, diputar oleh native).
          _soundExitAlarm();

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠ PERINGATAN! Anda tidak diperbolehkan keluar dari sesi ujian yang sedang berlangsung.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.error,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // Konfirmasi keluar untuk non-ujian
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Keluar dari Form?'),
              content: const Text('Jawaban Anda mungkin tidak tersimpan jika Anda keluar sekarang.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Ya, Keluar'),
                ),
              ],
            ),
          );
          
          if (!context.mounted) return;
          if (confirm == true) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark
                ? AppTheme.darkBg
                : AppTheme.surfaceLight,

        // ---------------------------------------------------------------
        // Bilah sistem bikinan aplikasi (Revisi Lanjutan 9).
        //
        // Halaman pengisian menutupi status bar HP, jadi jam + baterai
        // ditampilkan aplikasi sendiri tepat di atas AppBar. Tingginya
        // dijumlahkan dengan tinggi AppBar sehingga totalnya tetap satu
        // baris setinggi status bar — tidak memakan ruang extra.
        // ---------------------------------------------------------------
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            kToolbarHeight + _DeviceStatusBar.heightOf(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DeviceStatusBar(themeColor: widget.form.themeColor),
              Expanded(
                child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:
            FormTheme.resolvePrimary(context, widget.form.themeColor),
        title: Text(
          widget.form.title,
          style: const TextStyle(
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_examMode)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _hasUnsaved
                    ? 'Ada jawaban belum tersimpan'
                    : 'Semua jawaban tersimpan',
                child: Icon(
                  _hasUnsaved
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_done_rounded,
                  size: 20,
                  color: _hasUnsaved ? AppTheme.warning : Colors.white70,
                ),
              ),
            ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.grid_view_rounded, size: 22),
                if (_flags.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_flags.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: l10n.questionNo,
            onPressed: () => _showQuestionPanel(context),
          ),
          if (widget.form.hasTimer)
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
                top: 8,
                bottom: 8,
              ),
              child: TimerWidget(
                remainingSeconds: _remaining,
                isWarning: isWarn,
              ),
            ),
          ],
        ),
              ),
            ],
          ),
        ),

      body: Stack(
        children: [
          Column(
        children: [

          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                ),
              ),
            ),
            child: ListView.builder(
              controller: _numberStripController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              itemCount: _questions.length,
              itemBuilder: (context, i) {
                final isCurrent = i == _current;
                final isFlaggedQ = _flags.contains(i);
                final isAns = _isAnswered(i);

                Color bg;
                Color fg;
                Color borderC;

                if (isCurrent) {
                  bg = context.primary;
                  fg = Colors.white;
                  borderC = context.primary;
                } else if (isFlaggedQ) {
                  bg = AppTheme.warning.withValues(alpha: 0.18);
                  fg = AppTheme.warning;
                  borderC = AppTheme.warning;
                } else if (isAns) {
                  bg = AppTheme.success.withValues(alpha: 0.15);
                  fg = AppTheme.success;
                  borderC = AppTheme.success.withValues(alpha: 0.5);
                } else {
                  bg = isDark ? AppTheme.darkSurface : AppTheme.surfaceLight;
                  fg = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
                  borderC = isDark ? AppTheme.darkBorder : AppTheme.border;
                }

                return GestureDetector(
                  onTap: () => _jumpToQuestion(i),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderC,
                        width: isCurrent ? 2.0 : 1.2,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: context.primaryWith(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: fg,
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          if (isFlaggedQ && !isCurrent) ...[
                            const SizedBox(width: 1),
                            Icon(Icons.flag_rounded, size: 9, color: fg),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                context.primary,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            l10n.questionOf(_current + 1, _questions.length),
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      if (q.isRequired) ...[
                        const SizedBox(
                          width: 8,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppTheme
                                    .errorLight,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child:
                              Text(
                            l10n.required,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color:
                                  AppTheme
                                      .error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    q.text,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 22),

                  if (questionImagePath != null) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CustomPageRoute(page: FullScreenImageViewer(
                              filePath: questionImagePath,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.file(
                            File(questionImagePath),
                            fit: BoxFit.fitWidth,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 80,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  if (q.type == QuestionType.mathFormula && q.mathFormula != null) ...[
                    MathFormulaWidget(
                      formula: q.mathFormula!,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],

                    if (q.type ==
                            QuestionType
                                .codeInput &&
                        q.codeSnippet != null) ...[
                      CodeBlockWidget(
                        code:
                            q.codeSnippet!,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],

                    if (q.imageUrl != null) ...[
                      ImageZoomWidget(
                        imageUrl:
                            q.imageUrl!,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],

                    if (q.audioUrl != null) ...[
                      AudioPlayerWidget(audioSource: q.audioUrl!),
                      const SizedBox(height: 20),
                    ],

                  _buildAnswer(
                    q,
                    isDark,
                  ),

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _toggleFlag(_current),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _flags.contains(_current)
                            ? AppTheme.warning.withValues(alpha: 0.12)
                            : (isDark
                                ? AppTheme.darkCard
                                : AppTheme.surfaceCard),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _flags.contains(_current)
                              ? AppTheme.warning.withValues(alpha: 0.40)
                              : (isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.border),
                          width: _flags.contains(_current) ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 16,
                            color: _flags.contains(_current)
                                ? AppTheme.warning
                                : (isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.textMuted),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _flags.contains(_current)
                                ? l10n.unflagQuestion
                                : l10n.flagQuestion,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _flags.contains(_current)
                                  ? AppTheme.warning
                                  : (isDark
                                      ? AppTheme.darkTextMuted
                                      : AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _NavBar(
            current: _current,
            total: _questions.length,
            flaggedCount: _flags.length,
            isFlagged: _flags.contains(_current),
            onPrev:
                _previousQuestion,
            onNext:
                _nextQuestion,
            onSubmit:
                () => _submitForm(),
            onOpenPanel:
                () => _showQuestionPanel(context),
            onToggleFlag:
                () => _toggleFlag(_current),
          ),
        ],
      ),
          if (_examMode) ...[
            SecurityOverlayWidget(
              isVisible: _overlayWarningVisible,
              warningText: _overlayWarningText,
              violationCount: _violationCount,
              maxViolations: kMaxExitViolations,
            ),
            if (_overlayWarningVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _acknowledgeWarning,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'Saya Mengerti, Lanjutkan ($_violationCount/$kMaxExitViolations)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    ));
  }

  Widget _buildAnswer(
    QuestionModel q,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);

    switch (q.type) {
      case QuestionType.multipleChoice:
        return _MCAnswer(
          q: q,
          answers: _answers,
          isDark: isDark,
          onSelect: (id) {
            setState(() {
              _answers[q.id] = id;
            });
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.checkbox:
        final selected = (_answers[q.id] is Set<String>)
            ? _answers[q.id] as Set<String>
            : <String>{};
        return _CheckboxAnswer(
          q: q,
          selected: selected,
          isDark: isDark,
          onToggle: (id) {
            setState(() {
              final s = Set<String>.from(selected);
              if (s.contains(id)) {
                s.remove(id);
              } else {
                s.add(id);
              }
              _answers[q.id] = s;
            });
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.shortText:
        return _TextAnswer(
          controller:
              _getController(q.id),
          hint: l10n.shortAnsHint,
          maxLines: 1,
          onChanged: (v) {
            _answers[q.id] = v;
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.longText:
      case QuestionType.codeInput:
        return _TextAnswer(
          controller:
              _getController(q.id),
          hint:
              q.type ==
                      QuestionType
                          .codeInput
                  ? l10n.writeCodeHint
                  : l10n.typingAnsHint,
          maxLines: 6,
          monospace:
              q.type ==
                  QuestionType
                      .codeInput,
          onChanged: (v) {
            _answers[q.id] = v;
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.mathFormula:
        return _TextAnswer(
          controller:
              _getController(q.id),
          hint: l10n.writeFormulaHint,
          maxLines: 3,
          onChanged: (v) {
            _answers[q.id] = v;
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.rating:
        final rating =
            (_answers[q.id] as int?) ??
                0;

        return _RatingAnswer(
          rating: rating,
          max:
              q.ratingMax ?? 5,
          onRate: (r) {
            setState(() {
              _answers[q.id] = r;
            });
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.yesNo:
        return _YesNoAnswer(
          value:
              _answers[q.id] as String?,
          // `_answers` menyimpan **ID opsi** hasil [_yesNoOptionId], bukan teks
          // 'yes'/'no'. ID itu harus diresolusi lebih dulu supaya penyorotan
          // pilihan cocok dengan jawaban yang benar-benar tersimpan.
          yesOptionId:
              _yesNoOptionId(q, true),
          noOptionId:
              _yesNoOptionId(q, false),
          onSelect: (yes) {
            setState(() {
              _answers[q.id] =
                  _yesNoOptionId(q, yes);
            });
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.imageChoice:
        return _MCAnswer(
          q: q,
          answers: _answers,
          isDark: isDark,
          onSelect: (id) {
            setState(() {
              _answers[q.id] = id;
            });
            _dirtyQuestions.add(q.id);
          },
        );

      case QuestionType.matching:
        final rawAnswer = _answers[q.id];
        Map<String, String> currentMap = {};
        if (rawAnswer is Map) {
          currentMap = Map<String, String>.from(
            rawAnswer.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
        return _MatchingAnswer(
          question: q,
          currentAnswers: currentMap,
          isDark: isDark,
          onChanged: (map) {
            setState(() {
              _answers[q.id] = map;
            });
            _dirtyQuestions.add(q.id);
          },
        );
    }
  }

  /// ID opsi yang mewakili "Ya"/"Tidak" pada soal [q].
  ///
  /// Halaman pengisian menyimpan jawaban sebagai **ID opsi**
  /// (`selected_option_id` di backend), bukan teks 'yes'/'no'. Karena itu
  /// pemetaan id ⇄ tombol harus dihitung dari [q.options] dan TIDAK boleh
  /// mengandalkan teks mentah — itulah bug yang membuat tombol Ya/Tidak
  /// tampak "tidak bisa dipencet" (jawaban tersimpan, tapi tidak tersorot).
  ///
  /// Urutan pencarian teks: 'ya'/'yes'/'true'/'benar' untuk "Ya", dan
  /// 'tidak'/'no'/'false'/'salah' untuk "Tidak". Bila label tidak standar
  /// (mis. hasil AI "Opsi A"/"Opsi B"), urutan opsi dipakai sebagai cadangan:
  /// opsi pertama = Ya, opsi terakhir = Tidak.
  String? _yesNoOptionId(
    QuestionModel q,
    bool yes,
  ) {
    for (final opt in q.options) {
      final t = opt.text.trim().toLowerCase();
      if (yes && _yesTokens.contains(t)) {
        return opt.id;
      }
      if (!yes && _noTokens.contains(t)) {
        return opt.id;
      }
    }

    if (q.options.length >= 2) {
      return yes
          ? q.options.first.id
          : q.options.last.id;
    }

    // Satu opsi (atau tidak ada): tidak ada pasangan Ya/Tidak yang sah, jadi
    // jangan mengarang id. Tombolnya akan tampil nonaktif.
    return null;
  }
}

/// Bilah informasi ringkas bikinan aplikasi (jam + baterai) untuk halaman
/// pengisian.
///
/// Halaman pengisian menyembunyikan status bar HP, jadi widget ini
/// menggantinya. Sengaja TIDAK meniru status bar sungguhan (jarak, ikon
/// besar, huruf lebar) — yang dipakai hanya dua informasi yang benar-benar
/// dibutuhkan siswa: jam sekarang dan sisa baterai, masing-masing di dalam
/// "pill" kecil yang rapi.
///
/// Jam disegarkan tiap 20 detik. Baterai dibaca lewat channel native
/// `id.hidocs.app/security` (`getBatteryInfo`); bila tidak tersedia
/// (non-Android) chip baterainya disembunyikan dan jam tetap tampil.
class _DeviceStatusBar extends StatefulWidget {
  /// Warna tema form — dibuat sama dengan AppBar agar menyatu.
  final String themeColor;

  const _DeviceStatusBar({required this.themeColor});

  /// Total tinggi baris ini termasuk ruang notch/status bar tersembunyi.
  static double heightOf(BuildContext context) =>
      MediaQuery.of(context).padding.top + contentHeight;

  static const double contentHeight = 30;

  @override
  State<_DeviceStatusBar> createState() => _DeviceStatusBarState();
}

class _DeviceStatusBarState extends State<_DeviceStatusBar> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  BatteryInfo? _battery;

  @override
  void initState() {
    super.initState();
    _readBattery();
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _readBattery();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _readBattery() async {
    final info = await ExamSecurityService.getBatteryInfo();
    if (!mounted || info == null) return;
    setState(() => _battery = info);
  }

  String get _clock {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  IconData get _batteryIcon {
    final battery = _battery;
    if (battery == null) return Icons.battery_unknown_rounded;
    if (battery.charging) return Icons.battery_charging_full_rounded;
    final level = battery.level;
    if (level <= 10) return Icons.battery_0_bar_rounded;
    if (level <= 30) return Icons.battery_2_bar_rounded;
    if (level <= 50) return Icons.battery_3_bar_rounded;
    if (level <= 80) return Icons.battery_5_bar_rounded;
    return Icons.battery_full_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final background =
        FormTheme.resolvePrimary(context, widget.themeColor);
    final battery = _battery;

    return Container(
      color: background,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: _DeviceStatusBar.contentHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Jam — pill transparan, angka tabular supaya lebarnya stabil
              // dan tidak "berganti-ganti" tiap menit.
              _InfoPill(
                child: Text(
                  _clock,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              if (battery != null)
                _InfoPill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${battery.level}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        _batteryIcon,
                        color: battery.charging
                            ? Colors.amberAccent
                            : Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Pill" kecil transparan pembungkus satu potongan info pada [_DeviceStatusBar].
///
/// Dipakai supaya jam dan baterai terlihat sebagai dua unit info yang rapi,
/// bukan baris status yang meniru tampilan sistem. Latar putih transparan
/// tipis + radius penuh membuatnya menyatu dengan warna AppBar tanpa
/// menambah kotak-kotak berat.
class _InfoPill extends StatelessWidget {
  final Widget child;

  const _InfoPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }
}

class _SuccessScreen
    extends StatelessWidget {
  final VoidCallback onBack;

  const _SuccessScreen({
    required this.onBack,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n =
        AppLocalizations.of(context);

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBg
          : AppTheme.surfaceLight,
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(40),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration:
                    BoxDecoration(
                  color: AppTheme.success
                      .withValues(
                    alpha: 0.10,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .check_circle_rounded,
                  color:
                      AppTheme.success,
                  size: 52,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              Text(
                l10n.thankYou,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w800,
                  color: isDark
                      ? AppTheme
                          .darkTextPrimary
                      : AppTheme
                          .textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                l10n.submitSuccess,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppTheme
                          .darkTextSecondary
                      : AppTheme
                          .textMuted,
                ),
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 36,
              ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: GradientButton(
                  text: l10n.backToHome,
                  onPressed: onBack,
                  icon:
                      Icons.home_rounded,
                  fullWidth: true,
                  height: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBar
    extends StatelessWidget {
  final int current;
  final int total;
  final int flaggedCount;
  final bool isFlagged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final VoidCallback onOpenPanel;
  final VoidCallback onToggleFlag;

  const _NavBar({
    required this.current,
    required this.total,
    required this.flaggedCount,
    required this.isFlagged,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
    required this.onOpenPanel,
    required this.onToggleFlag,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n =
        AppLocalizations.of(context);

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final isLast =
        current == total - 1;

    final isFirst =
        current == 0;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        20,
      ),
      decoration:
          BoxDecoration(
        color: isDark
            ? AppTheme.darkCard
            : AppTheme.surfaceCard,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorder
                : AppTheme.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.05,
            ),
            blurRadius: 24,
            offset:
                const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flaggedCount > 0) ...[
              InkWell(
                onTap: onOpenPanel,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_rounded,
                          size: 14, color: AppTheme.warning),
                      const SizedBox(width: 6),
                      Text(
                        l10n.flagCountNote(flaggedCount),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 50,
                  child: IconButton(
                    icon: const Icon(Icons.grid_view_rounded, size: 20),
                    tooltip: l10n.questionNo,
                    padding: EdgeInsets.zero,
                    onPressed: onOpenPanel,
                  ),
                ),
                const SizedBox(width: 4),
                if (!isFirst) ...[
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: onPrev,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: isLast
                        ? _SafeGradientButton(
                            text: l10n.submitResponse,
                            icon: Icons.send_rounded,
                            onPressed: onSubmit,
                          )
                        : _SafeGradientButton(
                            text: l10n.next,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: onNext,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 50,
                  child: IconButton(
                    icon: Icon(
                      Icons.flag_rounded,
                      size: 20,
                      color: isFlagged
                          ? AppTheme.warning
                          : (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                    ),
                    tooltip: isFlagged ? l10n.unflagQuestion : l10n.flagQuestion,
                    padding: EdgeInsets.zero,
                    onPressed: onToggleFlag,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeGradientButton
    extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _SafeGradientButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child: Ink(
          decoration:
              BoxDecoration(
            gradient:
                LinearGradient(
              colors: [
                context.primary,
                context.primaryLight,
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 12,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Icon(
                  icon,
                  color:
                      Colors.white,
                  size: 19,
                ),
                const SizedBox(
                  width: 6,
                ),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MCAnswer
    extends StatelessWidget {
  final QuestionModel q;
  final Map<String, dynamic> answers;
  final bool isDark;
  final void Function(String) onSelect;

  const _MCAnswer({
    required this.q,
    required this.answers,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: q.options.map(
        (opt) {
          final selected =
              answers[q.id] ==
                  opt.id;

          return GestureDetector(
            onTap: () =>
                onSelect(opt.id),
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              margin:
                  const EdgeInsets
                      .only(
                bottom: 10,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration:
                  BoxDecoration(
                color: selected
                    ? context.primaryWith(0.07)
                    : (isDark
                        ? AppTheme
                            .darkCard
                        : AppTheme
                            .surfaceCard),
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
                border:
                    Border.all(
                  color: selected
                      ? context.primary
                      : (isDark
                          ? AppTheme
                              .darkBorder
                          : AppTheme
                              .border),
                  width:
                      selected
                          ? 2
                          : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds:
                          200,
                    ),
                    width: 22,
                    height: 22,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape
                              .circle,
                      color: selected
                          ? context.primary
                          : Colors
                              .transparent,
                      border:
                          Border.all(
                        color: selected
                            ? context.primary
                            : (isDark
                                ? AppTheme
                                    .darkBorder
                                : AppTheme
                                    .border),
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons
                                .check_rounded,
                            size: 14,
                            color: Colors
                                .white,
                          )
                        : null,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (opt.imageUrl != null) ...[
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: Image.network(
                              opt.imageUrl!,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const SizedBox(
                                height: 60,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color:
                                        AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                        ],
                        if (opt.content != null && opt.content!.isNotEmpty)
                          RichTextContentView(
                            content: opt.content,
                            fallbackText: opt.text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? context.primary
                                  : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary),
                            ),
                          )
                        else
                          Text(
                            opt.text,
                            style:
                                TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  selected
                                      ? FontWeight
                                          .w600
                                      : FontWeight
                                          .w400,
                              color: selected
                                  ? context.primary
                                  : (isDark
                                      ? AppTheme
                                          .darkTextSecondary
                                      : AppTheme
                                          .textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}

class _CheckboxAnswer extends StatelessWidget {
  final QuestionModel q;
  final Set<String> selected;
  final bool isDark;
  final void Function(String) onToggle;

  const _CheckboxAnswer({
    required this.q,
    required this.selected,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.primaryWith(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.primaryWith(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: context.primary),
              const SizedBox(width: 6),
              Text(
                l10n.chooseMultiple,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
              ),
            ],
          ),
        ),
        ...q.options.map((opt) {
          final isSelected = selected.contains(opt.id);

          return GestureDetector(
            onTap: () => onToggle(opt.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.primaryWith(0.07)
                    : (isDark ? AppTheme.darkCard : AppTheme.surfaceCard),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? context.primary
                      : (isDark ? AppTheme.darkBorder : AppTheme.border),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isSelected ? context.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? context.primary
                            : (isDark ? AppTheme.darkBorder : AppTheme.border),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (opt.imageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              opt.imageUrl!,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 60,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: AppTheme.textMuted),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (opt.content != null && opt.content!.isNotEmpty)
                          RichTextContentView(
                            content: opt.content,
                            fallbackText: opt.text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? context.primary
                                  : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary),
                            ),
                          )
                        else
                          Text(
                            opt.text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? context.primary
                                  : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TextAnswer
    extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool monospace;
  final void Function(String) onChanged;

  const _TextAnswer({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.monospace = false,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 15,
        fontFamily:
            monospace
                ? 'monospace'
                : null,
        color: isDark
            ? AppTheme
                .darkTextPrimary
            : AppTheme
                .textPrimary,
      ),
      decoration:
          InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark
            ? AppTheme.darkSurface
            : AppTheme.surfaceCard,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide(
            color: isDark
                ? AppTheme.darkBorder
                : AppTheme.border,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide(
            color: isDark
                ? AppTheme.darkBorder
                : AppTheme.border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide(
            color:
                context.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.all(
          16,
        ),
      ),
    );
  }
}

class _RatingAnswer
    extends StatelessWidget {
  final int rating;
  final int max;
  final void Function(int) onRate;

  const _RatingAnswer({
    required this.rating,
    required this.max,
    required this.onRate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children:
              List.generate(
            max,
            (i) {
              final filled =
                  i < rating;

              return GestureDetector(
                onTap: () =>
                    onRate(i + 1),
                child:
                    AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds:
                        150,
                  ),
                  child: Icon(
                    filled
                        ? Icons
                            .star_rounded
                        : Icons
                            .star_outline_rounded,
                    size:
                        filled
                            ? 40
                            : 34,
                    color: filled
                        ? AppTheme
                            .warning
                        : AppTheme
                            .textMuted,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          rating == 0
              ? l10n.notSelected
              : l10n.outOfStars(max, rating),
          style: TextStyle(
            fontSize: 13,
            color: rating == 0
                ? AppTheme
                    .textMuted
                : AppTheme
                    .warning,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _YesNoAnswer
    extends StatelessWidget {
  /// Jawaban tersimpan: **ID opsi** (bentuk normal) atau teks 'yes'/'no'
  /// (sesi lama). Lihat [FillFormScreen._yesNoOptionId].
  final String? value;

  /// ID opsi yang mewakili "Ya"/"Tidak" pada soal ini. Dibutuhkan supaya
  /// penyorotan pilihan membandingkan HAL YANG SAMA dengan yang disimpan.
  final String? yesOptionId;
  final String? noOptionId;

  final void Function(bool) onSelect;

  const _YesNoAnswer({
    required this.value,
    required this.yesOptionId,
    required this.noOptionId,
    required this.onSelect,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n =
        AppLocalizations.of(context);

    final yesSelected =
        _yesNoMatches(value, yesOptionId, _yesTokens);
    final noSelected =
        _yesNoMatches(value, noOptionId, _noTokens);

    return Row(
      children: [
        Expanded(
          child: _YNOption(
            label: l10n.yes,
            icon:
                Icons.check_circle_rounded,
            color:
                AppTheme.success,
            selected: yesSelected,
            // `null` = soal tidak punya dua opsi yang sah → tombol nonaktif,
            // bukan menyimpan id yang salah ke jawaban.
            onTap: yesOptionId == null
                ? null
                : () => onSelect(true),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: _YNOption(
            label: l10n.no,
            icon:
                Icons.cancel_rounded,
            color:
                AppTheme.error,
            selected: noSelected,
            onTap: noOptionId == null
                ? null
                : () => onSelect(false),
          ),
        ),
      ],
    );
  }
}

/// Teks jawaban yang diterima sebagai padanan "Ya"/"Tidak" saat jawaban
/// tersimpan berupa teks, bukan id opsi.
const Set<String> _yesTokens = {'yes', 'ya', 'true', 'benar'};
const Set<String> _noTokens = {'no', 'tidak', 'false', 'salah'};

/// [FillFormScreen._yesNoMatches] versi bebas-konteks untuk widget Ya/Tidak.
bool _yesNoMatches(
  String? value,
  String? optionId,
  Set<String> tokens,
) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return false;
  if (optionId != null && raw == optionId) return true;
  return tokens.contains(raw.toLowerCase());
}

class _YNOption
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;

  /// `null` = tombol tidak bisa ditekan (mis. soal Ya/Tidak tanpa dua opsi).
  final VoidCallback? onTap;

  const _YNOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    // Soal Ya/Tidak tanpa dua opsi yang sah tidak boleh menipu: tombolnya
    // tampil redup dan memang tidak bisa ditekan.
    final enabled = onTap != null;

    final Color idleColor = enabled
        ? AppTheme.textMuted
        : AppTheme.textMuted.withValues(alpha: 0.45);

    final Color borderColor = selected
        ? color
        : (isDark
            ? AppTheme.darkBorder
            : AppTheme.border);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: GestureDetector(
        // Area sentuh SELUAR tombol — termasuk saat belum dipilih, karena
        // kotak transparan tidak punya piksel untuk di-hit-test. Tanpa ini
        // ketukan di bagian kosong tombol terasa "tidak berfungsi".
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 200,
          ),
          height: 68,
          decoration:
              BoxDecoration(
            color: selected
                ? color.withValues(
                    alpha: 0.10,
                  )
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border:
                Border.all(
              color: enabled
                  ? borderColor
                  : borderColor.withValues(alpha: 0.50),
              width:
                  selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? color
                      : idleColor,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  label,
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color: selected
                        ? color
                        : idleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchingAnswer extends StatefulWidget {
  final QuestionModel question;
  final Map<String, String> currentAnswers;
  final bool isDark;
  final void Function(Map<String, String>) onChanged;

  const _MatchingAnswer({
    required this.question,
    required this.currentAnswers,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_MatchingAnswer> createState() => _MatchingAnswerState();
}

class _MatchingAnswerState extends State<_MatchingAnswer> {
  late Map<String, String> _selected;
  late List<String> _shuffledRights;

  @override
  void initState() {
    super.initState();
    _selected = Map<String, String>.from(widget.currentAnswers);
    _shuffledRights =
        widget.question.matchingPairs.map((p) => p.right).toList()..shuffle();
  }

  void _pick(String pairId, String? value) {
    setState(() {
      if (value == null) {
        _selected.remove(pairId);
      } else {
        _selected[pairId] = value;
      }
    });
    widget.onChanged(Map<String, String>.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pairs = widget.question.matchingPairs;

    if (pairs.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardColor =
        widget.isDark ? AppTheme.darkCard : AppTheme.surfaceCard;
    final borderColor =
        widget.isDark ? AppTheme.darkBorder : AppTheme.border;
    final textColor = widget.isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.textPrimary;
    final mutedColor =
        widget.isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: context.primaryWith(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.leftCol,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: context.primaryWith(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.choosePair,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        ...pairs.map((pair) {
          final picked = _selected[pair.id];
          final isAnswered = picked != null && picked.isNotEmpty;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAnswered
                    ? AppTheme.success.withValues(alpha: 0.35)
                    : borderColor,
                width: isAnswered ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pair.left,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: mutedColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? AppTheme.success.withValues(alpha: 0.06)
                          : (widget.isDark
                              ? AppTheme.darkSurface
                              : AppTheme.surfaceLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAnswered
                            ? AppTheme.success.withValues(alpha: 0.35)
                            : borderColor,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: picked,
                        isExpanded: true,
                        isDense: true,
                        hint: Text(
                          l10n.pick,
                          style: TextStyle(
                              fontSize: 13, color: mutedColor),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              l10n.clearChoice,
                              style: TextStyle(
                                  fontSize: 12, color: mutedColor),
                            ),
                          ),
                          ..._shuffledRights.map(
                            (r) => DropdownMenuItem<String>(
                              value: r,
                              child: Text(r,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => _pick(pair.id, v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool current;
  final bool outlined;
  const _LegendDot({
    required this.color,
    required this.label,
    this.current = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: outlined ? Colors.transparent : color,
          border: Border.all(
            color: outlined ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: current
            ? Center(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _SummaryLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Layar yang ditampilkan saat akses ujian dicabut karena pelanggaran keluar
/// melebihi batas (3x). Siswa tidak bisa melanjutkan ujian.
class _RevokedScreen extends StatelessWidget {
  final VoidCallback onBack;

  const _RevokedScreen({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    size: 52,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'AKSES UJIAN DICABUT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Anda telah melebihi batas maksimum pelanggaran '
                  'keluar dari aplikasi ujian ($kMaxExitViolations kali).\n\n'
                  'Sesi ujian ini telah ditutup secara otomatis. '
                  'Hubungi pengawas/creator untuk informasi lebih lanjut.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: const Text(
                      'Kembali ke Beranda',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
