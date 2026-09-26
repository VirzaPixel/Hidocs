import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/utils/constants.dart';
import 'package:hi_docs/services/security/question_image_renderer.dart';
import 'package:hi_docs/widgets/form/info_tab.dart';
import 'package:hi_docs/widgets/form/questions_tab.dart';
import 'package:hi_docs/widgets/form/settings_tab.dart';
import 'package:hi_docs/screens/forms/question_bank_screen.dart';

class CreateFormScreen extends StatefulWidget {
  final FormModel? existingForm;
  final List<QuestionModel>? initialQuestions;
  final int initialTabIndex;

  const CreateFormScreen({
    this.existingForm,
    this.initialQuestions,
    this.initialTabIndex = 0,
    super.key,
  });

  bool get isEditing => existingForm != null;

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> _categories = [];

  late TabController _tabCtrl;

  DateTime _openDate = DateTime.now();

  DateTime _closeDate = DateTime.now().add(
    const Duration(days: 1),
  );

  TimeOfDay _openTime = TimeOfDay.now();
  TimeOfDay _closeTime = TimeOfDay.now();

  bool _shuffleQ = false;
  bool _shuffleO = false;
  bool _oneTime = true;
  bool _isActive = true;
  int _durationLimitMinutes = 0;

  bool _isPublic = true;
  FormType _formType = FormType.survey;
  String _examToken = '';
  bool _isTokenProtected = false;

  ResultVisibility _resultVisibility =
      ResultVisibility.hidden;

  final List<QuestionModel> _questions = [];

  bool _isSaving = false;

  /// Simple list equality check (content comparison, not reference).
  bool _listEquals(List<QuestionModel> a, List<QuestionModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].text != b[i].text) return false;
    }
    return true;
  }

  bool _hasQuestionContent(QuestionModel q) {
    if (q.text.trim().isNotEmpty) return true;
    if (q.content != null && q.content!.trim().isNotEmpty) return true;

    if (q.type == QuestionType.codeInput &&
        (q.codeSnippet?.trim().isNotEmpty ?? false)) {
      return true;
    }

    if (q.type == QuestionType.mathFormula &&
        (q.mathFormula?.trim().isNotEmpty ?? false)) {
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();

    final existing = widget.existingForm;

    if (existing != null) {
      _titleCtrl.text = existing.title;
      _linkCtrl.text = existing.customLinkAlias.isEmpty
          ? existing.shortLink
          : existing.customLinkAlias;
      _categoryCtrl.text = existing.category;

      _openDate = DateTime(existing.scheduledOpen.year,
          existing.scheduledOpen.month, existing.scheduledOpen.day);
      _closeDate = DateTime(existing.scheduledClose.year,
          existing.scheduledClose.month, existing.scheduledClose.day);
      _openTime = TimeOfDay.fromDateTime(existing.scheduledOpen);
      _closeTime = TimeOfDay.fromDateTime(existing.scheduledClose);

      _shuffleQ = existing.shuffleQuestions;
      _shuffleO = existing.shuffleOptions;
      _oneTime = existing.oneTimeOnly;
      _isActive = existing.isActive;
      _isPublic = existing.isPublic;
      _formType = existing.formType;
      _examToken = existing.examToken;
      _isTokenProtected = existing.isTokenProtected;
      _resultVisibility = existing.resultVisibility;
      _durationLimitMinutes = existing.timerMinutes;
      _questions.addAll(existing.questions);
    } else if (widget.initialQuestions != null && widget.initialQuestions!.isNotEmpty) {
      _questions.addAll(widget.initialQuestions!);
    }

    _tabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    try {
      final fp = Provider.of<FormProvider>(context, listen: false);
      final cats = await fp.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
      });
    } catch (_) {}
  }

  Future<void> _openQuestionBank() async {
    final picked = await Navigator.push<List<QuestionModel>>(
      context,
      MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
    );
    if (picked == null || picked.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _questions.addAll(picked);
    });
    _tabCtrl.animateTo(2);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _categoryCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  DateTime get _openDateTime {
    return DateTime(
      _openDate.year,
      _openDate.month,
      _openDate.day,
      _openTime.hour,
      _openTime.minute,
    );
  }

  DateTime get _closeDateTime {
    return DateTime(
      _closeDate.year,
      _closeDate.month,
      _closeDate.day,
      _closeTime.hour,
      _closeTime.minute,
    );
  }



  int get _timerMinutes {
    return _durationLimitMinutes;
  }

  void _addQuestion(QuestionType type) {
    final timestamp =
        DateTime.now().microsecondsSinceEpoch;

    List<OptionModel> options = [];
    List<MatchingPair> matchingPairs = [];
    int? ratingMax;

    switch (type) {
      case QuestionType.multipleChoice:
      case QuestionType.checkbox:
      case QuestionType.imageChoice:
        options = [
          OptionModel(
            id: 'o${timestamp}1',
            text: 'Option 1',
          ),
          OptionModel(
            id: 'o${timestamp}2',
            text: 'Option 2',
          ),
        ];
      case QuestionType.yesNo:
        options = [
          OptionModel(
            id: 'o${timestamp}y',
            text: 'Yes',
          ),
          OptionModel(
            id: 'o${timestamp}n',
            text: 'No',
          ),
        ];
      case QuestionType.rating:
        ratingMax = 5;
      case QuestionType.matching:
        matchingPairs = List.generate(
          3,
          (i) => MatchingPair(id: 'm${timestamp}_$i', left: '', right: ''),
        );
      case QuestionType.shortText:
      case QuestionType.longText:
      case QuestionType.codeInput:
      case QuestionType.mathFormula:
        break;
    }

    final question = QuestionModel(
      id: 'q$timestamp',
      type: type,
      text: '',
      isRequired: true,
      ratingMax: ratingMax,
      hasScore: false,
      score: 0,
      options: options,
      matchingPairs: matchingPairs,
    );

    setState(() {
      _questions.add(question);
    });

    _tabCtrl.animateTo(2);
  }

  void _removeQuestion(int index) {
    if (index < 0 ||
        index >= _questions.length) {
      return;
    }

    setState(() {
      _questions.removeAt(index);
    });
  }

  void _reorderQuestion(
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < 0 ||
        oldIndex >= _questions.length ||
        newIndex < 0 ||
        newIndex > _questions.length) {
      return;
    }

    setState(() {
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }

  String _generateSlug(String title) {
    var slug = title
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (slug.isEmpty) {
      slug = 'form';
    }

    if (slug.length > 20) {
      slug = slug.substring(0, 20);
      slug = slug.replaceAll(
        RegExp(r'-+$'),
        '',
      );
    }

    return slug;
  }

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Tampilkan dialog error yang bertahan sampai ditutup — dipakai untuk
  /// kegagalan simpan form/soal yang harus DIBACA pengguna, bukan SnackBar
  /// sekejap yang hilang sebelum sempat dibaca.
  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.error_outline_rounded,
          color: AppTheme.error,
          size: 36,
        ),
        title: Text(
          l10n.isIndonesian ? 'Gagal menyimpan' : 'Save failed',
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
            label:
                Text(l10n.isIndonesian ? 'Salin pesan' : 'Copy message'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.isIndonesian ? 'Tutup' : 'Close'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog peringatan SEBELUM meninggalkan layar — dipakai
  /// ketika form berhasil dibuat/diperbarui tapi ada soal yang gagal
  /// tersimpan. Dialog bertahan sampai ditutup, menyertakan tombol
  /// "Salin pesan" agar bisa dilaporkan.
  Future<void> _showWarningDialog(String message) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.warning,
          size: 36,
        ),
        title: Text(
          l10n.isIndonesian
              ? 'Form disimpan — ada soal yang gagal'
              : 'Form saved — some questions failed',
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
                        ? 'Pesan disalin.'
                        : 'Message copied.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label:
                Text(l10n.isIndonesian ? 'Salin pesan' : 'Copy message'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.isIndonesian ? 'OK, lanjutkan' : 'OK, continue'),
          ),
        ],
      ),
    );
  }

  /// Converts every question into a local PNG (temp dir only — no
  /// database/backend). Cached by content hash so unchanged questions are
  /// skipped instantly. Failures are non-blocking: the fill screen falls
  /// back to normal rendering when an image is missing.
  Future<void> _prepareQuestionImages() async {
    if (_questions.isEmpty) return;

    final progress = ValueNotifier<MapEntry<int, int>>(
      const MapEntry(0, 0),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: ValueListenableBuilder<MapEntry<int, int>>(
              valueListenable: progress,
              builder: (context, value, _) {
                final done = value.key;
                final total = value.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value:
                          total == 0 ? null : (done / total).clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      total == 0
                          ? AppLocalizations.of(context).prepQuestionImages
                          : done >= total
                              ? AppLocalizations.of(context).finishingUp
                              : AppLocalizations.of(context)
                                  .convertingQuestionsToImages(done, total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    try {
      await QuestionImageRenderer.renderAll(
        _questions,
        context: context,
        onProgress: (done, total) {
          progress.value = MapEntry(done, total);
        },
      );
    } catch (_) {
      // Rendering is best-effort only.
    } finally {
      progress.dispose();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Aksi cepat "nilai semua soal" / "hapus nilai" (ala Google Forms).
  void _setScoringForAll(bool enabled) {
    setState(() {
      for (final q in _questions) {
        if (!q.isScorable) continue;
        q.hasScore = enabled;
        if (enabled) {
          if (q.score <= 0) q.score = 10;
        } else {
          q.score = 0;
        }
      }
    });
  }

  /// Terapkan nilai poin yang sama ke seluruh soal yang sedang dinilai.
  void _applyPointsToAll(int points) {
    final clamped = points.clamp(0, 100).toDouble();
    setState(() {
      for (final q in _questions) {
        if (!q.isScorable || !q.hasScore) continue;
        q.score = clamped;
      }
    });
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;

    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      _tabCtrl.animateTo(0);
      return;
    }

    if (_questions.isEmpty) {
      _showMessage(
        l10n.addAtLeastOneQuestion,
        backgroundColor: AppTheme.warning,
      );

      _tabCtrl.animateTo(2);
      return;
    }

    for (var i = 0; i < _questions.length; i++) {
      if (!_hasQuestionContent(_questions[i])) {
        _showMessage(
          l10n.questionContentEmpty(i + 1),
          backgroundColor: AppTheme.warning,
        );

        _tabCtrl.animateTo(2);
        return;
      }
      final q = _questions[i];
      // Pilihan ganda, kotak centang, pilihan gambar & ya/tidak wajib punya
      // minimal satu kunci jawaban BENAR hanya jika soal ikut dinilai
      // (seperti Google Forms: soal survei boleh tanpa kunci).
      final isChoice = q.type == QuestionType.multipleChoice ||
          q.type == QuestionType.checkbox ||
          q.type == QuestionType.imageChoice ||
          q.type == QuestionType.yesNo;
      if (isChoice && q.hasScore) {
        final hasCorrect = q.options.any((o) => o.isCorrect);
        if (!hasCorrect) {
          _showMessage(
            l10n.mcqNeedsCorrectAnswer(i + 1),
            backgroundColor: AppTheme.warning,
          );
          _tabCtrl.animateTo(2);
          return;
        }
      }
      if (q.type == QuestionType.matching &&
          !q.matchingPairs.any((p) => p.isComplete)) {
        _showMessage(
          l10n.isIndonesian
              ? 'Soal ${i + 1}: pasangan yang dicocokkan masih kosong.'
              : 'Question ${i + 1}: matching pairs are still empty.',
          backgroundColor: AppTheme.warning,
        );
        _tabCtrl.animateTo(2);
        return;
      }
    }

    // Cegah edit soal/settings saat form ACTIVE — guru harus deaktivasi dulu.
    // Metadata (title, category) tetap bisa diupdate meski form aktif.
    if (widget.isEditing && widget.existingForm!.isActive) {
      // Izinkan perubahan metadata saja (title & category sudah di-save lewat
      // toUpdateJson), tapi tolak jika soal/settings berubah.
      final original = widget.existingForm!;
      final questionsChanged =
          _questions.length != original.questions.length ||
              !_listEquals(_questions, original.questions);
      final settingsChanged =
          _shuffleQ != original.shuffleQuestions ||
              _shuffleO != original.shuffleOptions ||
              _oneTime != original.oneTimeOnly ||
              _timerMinutes != original.timerMinutes ||
              _resultVisibility != original.resultVisibility;

      if (questionsChanged || settingsChanged) {
        _showMessage(
          l10n.isIndonesian
              ? 'Form sedang aktif. Nonaktifkan dulu untuk mengubah soal atau pengaturan.'
              : 'Form is active. Deactivate it to change questions or settings.',
          backgroundColor: AppTheme.error,
        );
        _tabCtrl.animateTo(1);
        return;
      }
    }

    if (_closeDateTime.isBefore(_openDateTime)) {
      _showMessage(
        l10n.closeTimeBeforeOpenTime,
        backgroundColor: AppTheme.error,
      );

      _tabCtrl.animateTo(0);
      return;
    }

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final formProvider = Provider.of<FormProvider>(
      context,
      listen: false,
    );

    final currentUser = auth.currentUser;

    if (currentUser == null) {
      _showMessage(
        l10n.mustBeLoggedInToCreateForm,
        backgroundColor: AppTheme.error,
      );
      return;
    }

    final title = _titleCtrl.text.trim();
    final customAlias = _linkCtrl.text.trim();

    final slug = customAlias.isEmpty
        ? _generateSlug(title)
        : customAlias;

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();

    final editing = widget.existingForm;

    final form = FormModel(
      id: editing?.id ?? 'form${now.millisecondsSinceEpoch}',
      title: title,
      creatorId: currentUser.id,
      formType: _formType,
      category: _categoryCtrl.text.trim(),
      examToken: _examToken.trim(),
      isTokenProtected: _isTokenProtected,
      shortLink: slug,
      customLinkAlias: customAlias,
      scheduledOpen: _openDateTime,
      scheduledClose: _closeDateTime,
      timerMinutes: _timerMinutes,
      isPublic: _isPublic,
      shuffleQuestions: _shuffleQ,
      shuffleOptions: _shuffleO,
      oneTimeOnly: _oneTime,
      isActive: _isActive,
      resultVisibility: _resultVisibility,
      questions: List<QuestionModel>.from(
        _questions,
      ),
      createdAt: editing?.createdAt ?? now,
    );

    final ok = editing != null
        ? await formProvider.updateForm(form)
        : await formProvider.createForm(form);

    if (!mounted) {
      return;
    }

    if (!ok) {
      setState(() {
        _isSaving = false;
      });

      final errorMessage = formProvider.error ?? l10n.formSaveError;

      formProvider.clearError();

      // Gunakan dialog yang bertahan — bukan SnackBar yang hilang sebelum
      // sempat dibaca. Pengguna perlu tahu MENGAPA simpan gagal dan apa
      // yang harus dilakukan.
      await _showErrorDialog(errorMessage);

      return;
    }

    await _prepareQuestionImages();

    if (!mounted) {
      return;
    }

    // Ambil peringatan soal SEBELUM menutup layar supaya dialog bisa
    // tampil di atas layar buat-form, bukan tumpang-tindih dengan
    // layar sebelumnya.
    final warning = formProvider.saveWarning;
    formProvider.clearSaveWarning();

    if (warning != null) {
      // Soal tertentu gagal disimpan — tampilkan dialog agar pengguna
      // tahu persis soal mana yang bermasalah dan pesan errornya, lalu
      // baru kembali ke layar sebelumnya.
      await _showWarningDialog(warning);
    }

    if (!mounted) return;
    Navigator.pop(context);

    // Tampilkan konfirmasi singkat di layar sebelumnya kalau tidak ada warning.
    if (warning == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing != null
                ? l10n.formUpdatedSuccess
                : l10n.formCreatedSuccess,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editForm : l10n.createForm),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: l10n.tabInfo),
            Tab(text: l10n.tabSettings),
            Tab(text: l10n.tabQuestions),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saveForm,
            child: Text(
              l10n.save,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            InfoTab(
              titleController: _titleCtrl,
              linkController: _linkCtrl,
              categoryController: _categoryCtrl,
              categories: _categories,
              openDate: _openDate,
              closeDate: _closeDate,
              openTime: _openTime,
              closeTime: _closeTime,
              timerMinutes: _timerMinutes,
              isPublic: _isPublic,
              onIsPublic: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
              onOpenDate: (date) {
                setState(() {
                  _openDate = date;
                });
              },
              onCloseDate: (date) {
                setState(() {
                  _closeDate = date;
                });
              },
              onOpenTime: (time) {
                setState(() {
                  _openTime = time;
                });
              },
              onCloseTime: (time) {
                setState(() {
                  _closeTime = time;
                });
              },
              onDurationMinutes: (minutes) {
                setState(() {
                  _durationLimitMinutes = minutes;
                });
              },
            ),
            SettingsTab(
              formType: _formType,
              onFormTypeChanged: (type) {
                setState(() {
                  _formType = type;
                  if (type == FormType.exam && _examToken.isEmpty) {
                    _examToken = generateRandomLink(6).toUpperCase();
                  }
                });
              },
              examToken: _examToken,
              isTokenProtected: _isTokenProtected,
              onExamTokenChanged: (value) {
                setState(() {
                  _examToken = value;
                });
              },
              onIsTokenProtectedChanged: (value) {
                setState(() {
                  _isTokenProtected = value;
                });
              },
              questions: _questions,
              onSetScoringForAll: _setScoringForAll,
              onApplyPointsToAll: _applyPointsToAll,
              shuffleQuestion: _shuffleQ,
              shuffleOption: _shuffleO,
              oneTime: _oneTime,
              active: _isActive,
              visibility: _resultVisibility,
              timerMinutes: _timerMinutes,
              onShuffleQuestion: (value) {
                setState(() {
                  _shuffleQ = value;
                });
              },
              onShuffleOption: (value) {
                setState(() {
                  _shuffleO = value;
                });
              },
              onOneTime: (value) {
                setState(() {
                  _oneTime = value;
                });
              },
              onActive: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              onVisibility: (value) {
                setState(() {
                  _resultVisibility = value;
                });
              },
            ),
            QuestionsTab(
              questions: _questions,
              addQuestion: _addQuestion,
              removeQuestion: _removeQuestion,
              reorderQuestion: _reorderQuestion,
              onPickFromBank: _openQuestionBank,
              onQuestionsChanged: (updated) {
                setState(() {
                  _questions
                    ..clear()
                    ..addAll(updated);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

