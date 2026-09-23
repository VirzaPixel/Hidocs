import 'dart:async';
import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/services/api/api_client.dart';
import 'package:hi_docs/widgets/form/quill_embeds.dart';

class QuestionsTab extends StatefulWidget {
  final List<QuestionModel> questions;
  final void Function(QuestionType) addQuestion;
  final void Function(int) removeQuestion;
  final void Function(int, int) reorderQuestion;
  final void Function(List<QuestionModel>) onQuestionsChanged;
  final VoidCallback? onPickFromBank;

  const QuestionsTab({
    super.key,
    required this.questions,
    required this.addQuestion,
    required this.removeQuestion,
    required this.reorderQuestion,
    required this.onQuestionsChanged,
    this.onPickFromBank,
  });

  @override
  State<QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<QuestionsTab> {
  void _updateQuestion(QuestionModel updated) {
    final list = List<QuestionModel>.from(widget.questions);
    final idx = list.indexWhere((q) => q.id == updated.id);
    if (idx < 0) return;
    list[idx] = updated;
    widget.onQuestionsChanged(list);
  }

  void _showAddMenu() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.addQuestionLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _questionTypeTile(
                    icon: Icons.radio_button_checked,
                    title: l10n.qMultipleChoice,
                    subtitle: l10n.qMultipleChoiceSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.multipleChoice);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.image_outlined,
                    title: l10n.qImageChoice,
                    subtitle: l10n.qImageChoiceSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.imageChoice);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.subject_rounded,
                    title: l10n.qEssay,
                    subtitle: l10n.qEssaySub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.longText);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.short_text_rounded,
                    title: l10n.qShortAnswer,
                    subtitle: l10n.qShortAnswerSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.shortText);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.check_circle_outline,
                    title: l10n.qYesNo,
                    subtitle: l10n.qYesNoSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.yesNo);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.star_outline_rounded,
                    title: l10n.qRating,
                    subtitle: l10n.qRatingSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.rating);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.functions_rounded,
                    title: l10n.qMathFormula,
                    subtitle: l10n.qMathFormulaSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.mathFormula);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.check_box_outlined,
                    title: l10n.qCheckbox,
                    subtitle: l10n.qCheckboxSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.checkbox);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.compare_arrows_rounded,
                    title: l10n.qMatching,
                    subtitle: l10n.qMatchingSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.matching);
                    },
                  ),
                  _questionTypeTile(
                    icon: Icons.code_rounded,
                    title: l10n.qCodeInput,
                    subtitle: l10n.qCodeInputSub,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      widget.addQuestion(QuestionType.codeInput);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _questionTypeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.primaryWith(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: context.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (widget.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: context.primaryWith(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 40,
                  color: context.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noQuestionsYetTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noQuestionsYetSub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showAddMenu,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addQuestionLabel),
                ),
              ),
              if (widget.onPickFromBank != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onPickFromBank,
                    icon: const Icon(Icons.library_books_outlined),
                    label: Text(l10n.takeFromBank),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final totalPoints = widget.questions.fold<double>(
      0,
      (sum, q) => sum + (q.isScorable && q.hasScore ? q.score : 0),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: context.primaryWith(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.primaryWith(0.20)),
          ),
          child: Row(
            children: [
              Icon(Icons.stars_rounded, size: 20, color: context.primary),
              const SizedBox(width: 10),
              Text(
                l10n.isIndonesian
                    ? 'Total Poin Form: ${totalPoints.round()} Poin (${widget.questions.length} Soal)'
                    : 'Total Form Points: ${totalPoints.round()} Pts (${widget.questions.length} Questions)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: widget.questions.length,
            itemBuilder: (context, index) {
              final question = widget.questions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuestionCard(
                  key: ValueKey('${question.id}_${question.type.name}'),
                  question: question,
                  index: index,
                  total: widget.questions.length,
                  onChanged: _updateQuestion,
                  onDelete: () => widget.removeQuestion(index),
                  onMoveUp: index > 0
                      ? () => widget.reorderQuestion(index, index - 1)
                      : null,
                  onMoveDown: index < widget.questions.length - 1
                      ? () => widget.reorderQuestion(index, index + 1)
                      : null,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onPickFromBank != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onPickFromBank,
                    icon: const Icon(Icons.library_books_outlined),
                    label: Text(l10n.takeFromBank),
                  ),
                ),
              if (widget.onPickFromBank != null) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showAddMenu,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addQuestionLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final int index;
  final int total;
  final void Function(QuestionModel) onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.onChanged,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _syncTimer;
  bool _isUpdatingDocument = false;
  String? _lastSyncedContent;
  bool _showFormatting = false;

  /// Panel "Pengaturan lanjutan" (wajib dijawab, poin, gambar) tertutup
  /// secara default supaya kartu soal tetap ringkas dan tidak menumpuk.
  bool _showAdvanced = false;

  /// Toolbar WYSIWYG hanya tampil saat guru benar-benar mengisi teks soal
  /// (atau saat tombol "Format Teks" ditekan manual).
  bool _editorFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _controller.addListener(_onDocumentChanged);
    _focusNode.addListener(_onFocusChanged);
    _loadFromQuestion();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus == _editorFocused) return;
    setState(() {
      _editorFocused = _focusNode.hasFocus;
      if (!_focusNode.hasFocus) _showFormatting = false;
    });
  }

  @override
  void didUpdateWidget(covariant _QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question.content != _lastSyncedContent) {
      _loadFromQuestion();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFromQuestion() {
    _isUpdatingDocument = true;
    try {
      final content = widget.question.content;
      if (content != null && content.trim().isNotEmpty) {
        _controller.document = Document.fromJson(jsonDecode(content) as List);
      } else {
        final t = widget.question.text.trim();
        if (t.isEmpty) {
          _controller.document = Document();
        } else {
          _controller.document =
              Document.fromDelta(Delta()..insert(t)..insert('\n'));
        }
      }
      _lastSyncedContent = widget.question.content;
    } catch (_) {
      _controller.document = Document();
      _lastSyncedContent = widget.question.content;
    } finally {
      _isUpdatingDocument = false;
    }
  }

  void _onDocumentChanged() {
    if (_isUpdatingDocument) return;

    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final content = _serializeContent();
      final text = _controller.document.toPlainText().trim();
      _lastSyncedContent = content;
      widget.onChanged(
        _copy(
          widget.question,
          text: text,
          content: content,
        ),
      );
    });
  }

  String? _serializeContent() {
    final ops = _controller.document.toDelta().toList();
    final jsonOps = ops.map((op) => op.toJson()).toList();
    if (jsonOps.length == 1 && jsonOps.first['insert'] == '\n') {
      return null;
    }
    return jsonEncode(jsonOps);
  }

  QuestionModel _copy(
    QuestionModel q, {
    QuestionType? type,
    String? text,
    String? content,
    String? imageUrl,
    String? mathFormula,
    String? codeSnippet,
    List<OptionModel>? options,
    List<MatchingPair>? matchingPairs,
    bool? isRequired,
    int? ratingMax,
    int? correctRating,
    bool? hasScore,
    double? score,
  }) {
    String? resolvedImageUrl;
    if (imageUrl == null) {
      resolvedImageUrl = q.imageUrl;
    } else if (imageUrl.isEmpty) {
      resolvedImageUrl = null;
    } else {
      resolvedImageUrl = imageUrl;
    }
    return QuestionModel(
      id: q.id,
      type: type ?? q.type,
      text: text ?? q.text,
      content: content ?? q.content,
      imageUrl: resolvedImageUrl,
      mathFormula: mathFormula ?? q.mathFormula,
      codeSnippet: codeSnippet ?? q.codeSnippet,
      options: options ?? q.options,
      matchingPairs: matchingPairs ?? q.matchingPairs,
      isRequired: isRequired ?? q.isRequired,
      ratingMax: ratingMax ?? q.ratingMax,
      correctRating: correctRating ?? q.correctRating,
      scoreVisibility: q.scoreVisibility,
      hasScore: hasScore ?? q.hasScore,
      score: score ?? q.score,
    );
  }

  Future<void> _pickQuestionImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 1 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.isIndonesian ? 'Ukuran gambar maksimal 1 MB' : 'Image max 1 MB'), backgroundColor: AppTheme.error));
        return;
      }
      // Show uploading indicator
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.isIndonesian ? 'Mengupload gambar...' : 'Uploading image...')));
      final fileName = picked.name.isNotEmpty ? picked.name : 'question_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String? uploadedUrl;
      try {
        uploadedUrl = await ApiClient.uploadQuestionImage(bytes, fileName);
      } catch (_) {}
      String finalUrl;
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        // Backend returns /uploads/... need full baseUrl prefix if relative
        if (uploadedUrl.startsWith('/')) {
          final base = ApiClient.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');
          finalUrl = '$base$uploadedUrl';
          // alternative: keep relative, Image.network will fail without base, so use base+path
          // If backend already returns full URL, keep as is
          if (uploadedUrl.startsWith('http')) finalUrl = uploadedUrl;
        } else {
          finalUrl = uploadedUrl;
        }
      } else {
        // Fallback base64 dataUrl for preview (will not persist if server ignores, but shows)
        final ext = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
        finalUrl = 'data:image/$ext;base64,${base64Encode(bytes)}';
      }
      widget.onChanged(_copy(widget.question, imageUrl: finalUrl));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.failedToInsertImage}: $e'), backgroundColor: AppTheme.error));
    }
  }

  void _removeQuestionImage() {
    widget.onChanged(_copy(widget.question, imageUrl: ''));
  }

  Future<void> _pickOptionImage(int index) async {
    final l10n = AppLocalizations.of(context);
    try {
      final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 1 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.isIndonesian ? 'Ukuran gambar maksimal 1 MB' : 'Image max 1 MB'), backgroundColor: AppTheme.error));
        return;
      }
      String? uploadedUrl;
      try {
        final fileName = picked.name.isNotEmpty ? picked.name : 'option_${DateTime.now().millisecondsSinceEpoch}.jpg';
        uploadedUrl = await ApiClient.uploadQuestionImage(bytes, fileName);
        if (uploadedUrl != null && uploadedUrl.startsWith('/')) {
          final base = ApiClient.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');
          uploadedUrl = '$base$uploadedUrl';
        }
      } catch (_) {}
      final ext = picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final dataUrl = 'data:image/$ext;base64,${base64Encode(bytes)}';
      final finalUrl = (uploadedUrl != null && uploadedUrl.isNotEmpty) ? uploadedUrl : dataUrl;
      final opts = List<OptionModel>.from(widget.question.options);
      opts[index] = opts[index].copyWith(imageUrl: finalUrl);
      widget.onChanged(_copy(widget.question, options: opts));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.failedToInsertImage}: $e'), backgroundColor: AppTheme.error));
    }
  }

  void _removeOptionImage(int index) {
    final opts = List<OptionModel>.from(widget.question.options);
    opts[index] = OptionModel(
      id: opts[index].id,
      text: opts[index].text,
      content: opts[index].content,
      imageUrl: null,
      score: opts[index].score,
      isCorrect: opts[index].isCorrect,
    );
    widget.onChanged(_copy(widget.question, options: opts));
  }

  void _changeType(QuestionType type) {
    if (type == widget.question.type) return;
    final q = widget.question;

    QuestionModel updated;
    switch (type) {
      case QuestionType.multipleChoice:
      case QuestionType.checkbox:
      case QuestionType.imageChoice:
        final ts = DateTime.now().microsecondsSinceEpoch;
        var options = q.options.isEmpty
            ? [
                OptionModel(
                  id: 'o${ts}1',
                  text: 'Opsi 1',
                ),
                OptionModel(
                  id: 'o${ts}2',
                  text: 'Opsi 2',
                ),
              ]
            : q.options;
        if (options.length < 2) {
          options = [
            ...options,
            OptionModel(id: 'o${ts}x', text: 'Opsi ${options.length + 1}'),
          ];
        }
        // Pertahankan jawaban benar saat berpindah antar tipe pilihan
        // (pilihan ganda <-> kotak centang <-> pilihan gambar) supaya guru
        // tidak perlu menandai ulang tiap kali berganti tipe.
        if (type != QuestionType.checkbox) {
          var kept = false;
          options = options.map((o) {
            final keep = o.isCorrect && !kept;
            if (keep) kept = true;
            return o.copyWith(isCorrect: keep, score: keep ? 1 : 0);
          }).toList();
        }
        updated = _copy(q, type: type, options: options);
      case QuestionType.yesNo:
        final ts = DateTime.now().microsecondsSinceEpoch;
        updated = _copy(q, type: type, options: [
          OptionModel(id: 'o${ts}y', text: 'Yes'),
          OptionModel(id: 'o${ts}n', text: 'No'),
        ]);
      case QuestionType.rating:
        updated = _copy(q, type: type, options: [], ratingMax: q.ratingMax ?? 5);
      case QuestionType.shortText:
      case QuestionType.longText:
      case QuestionType.codeInput:
      case QuestionType.mathFormula:
        updated = _copy(q, type: type, options: []);
      case QuestionType.matching:
        final ts = DateTime.now().microsecondsSinceEpoch;
        final pairs = q.matchingPairs.isEmpty
            ? List.generate(
                3,
                (i) => MatchingPair(id: 'm${ts}_$i', left: '', right: ''),
              )
            : q.matchingPairs;
        updated = _copy(q, type: type, options: [], matchingPairs: pairs);
    }
    widget.onChanged(updated);
  }

  void _setOptions(List<OptionModel> opts) {
    widget.onChanged(_copy(widget.question, options: opts));
  }

  void _addOption() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final opts = [
      ...widget.question.options,
      OptionModel(
        id: 'o${ts}_${widget.question.options.length}',
        text: 'Option ${widget.question.options.length + 1}',
      ),
    ];
    _setOptions(opts);
  }

  void _removeOption(int i) {
    final opts = List<OptionModel>.from(widget.question.options)..removeAt(i);
    _setOptions(opts);
  }

  void _updateOptionText(int i, String text) {
    final opts = List<OptionModel>.from(widget.question.options);
    opts[i] = opts[i].copyWith(text: text);
    _setOptions(opts);
  }

  void _setCorrectOption(int i) {
    final multi = widget.question.allowsMultipleCorrectAnswers;
    final opts = widget.question.options.asMap().entries.map((e) {
      if (e.key == i) {
        // Kotak centang (checkbox) = boleh lebih dari satu jawaban benar,
        // jadi klik berarti toggle. Pilihan ganda hanya boleh satu.
        final next = multi ? !e.value.isCorrect : true;
        return e.value.copyWith(isCorrect: next, score: next ? 1 : 0);
      }
      if (multi) return e.value;
      return e.value.copyWith(isCorrect: false, score: 0);
    }).toList();
    _setOptions(opts);
  }

  void _setCorrectRating(int value) {
    widget.onChanged(_copy(widget.question, correctRating: value));
  }

  void _setMatchingPairs(List<MatchingPair> pairs) {
    widget.onChanged(_copy(widget.question, matchingPairs: pairs));
  }

  void _addMatchingPair() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    _setMatchingPairs([
      ...widget.question.matchingPairs,
      MatchingPair(
        id: 'm${ts}_${widget.question.matchingPairs.length}',
        left: '',
        right: '',
      ),
    ]);
  }

  void _removeMatchingPair(int i) {
    final pairs = List<MatchingPair>.from(widget.question.matchingPairs)
      ..removeAt(i);
    _setMatchingPairs(pairs);
  }

  void _updateMatchingLeft(int i, String value) {
    final pairs = List<MatchingPair>.from(widget.question.matchingPairs);
    pairs[i] = MatchingPair(id: pairs[i].id, left: value, right: pairs[i].right);
    _setMatchingPairs(pairs);
  }

  void _updateMatchingRight(int i, String value) {
    final pairs = List<MatchingPair>.from(widget.question.matchingPairs);
    pairs[i] = MatchingPair(id: pairs[i].id, left: pairs[i].left, right: value);
    _setMatchingPairs(pairs);
  }

  void _setRatingMax(int value) {
    widget.onChanged(
      _copy(widget.question, ratingMax: value, correctRating: null),
    );
  }

  void _toggleRequired(bool value) {
    widget.onChanged(_copy(widget.question, isRequired: value));
  }

  void _setMathFormula(String value) {
    widget.onChanged(_copy(widget.question, mathFormula: value));
  }

  void _setCodeSnippet(String value) {
    widget.onChanged(_copy(widget.question, codeSnippet: value));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEditor(isDark),
                const SizedBox(height: 12),
                ..._buildBody(isDark),
                const SizedBox(height: 6),
                _buildAdvancedToggle(isDark),
                if (_showAdvanced) ...[
                  const SizedBox(height: 4),
                  _buildQuestionImage(isDark),
                  _buildRequiredRow(isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Baris ringkas "Pengaturan lanjutan". Semua opsi yang jarang dipakai
  /// (wajib dijawab, poin, gambar soal) disembunyikan di balik baris ini agar
  /// halaman tidak terlihat penuh — ramah untuk guru yang belum terbiasa.
  Widget _buildAdvancedToggle(bool isDark) {
    final q = widget.question;
    final l10n = AppLocalizations.of(context);
    final muted = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final label = l10n.isIndonesian ? 'Pengaturan lanjutan' : 'More options';

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 16, color: muted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
                const SizedBox(width: 8),
                if (q.hasScore && q.score > 0)
                  _MiniBadge(
                    icon: Icons.stars_rounded,
                    text: '${q.score.round()}',
                    color: context.primary,
                    isDark: isDark,
                  ),
                if (q.isRequired)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _MiniBadge(
                      icon: Icons.verified_user_outlined,
                      text: l10n.isIndonesian ? 'Wajib' : 'Required',
                      color: AppTheme.success,
                      isDark: isDark,
                    ),
                  ),
                if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _MiniBadge(
                      icon: Icons.image_outlined,
                      text: l10n.isIndonesian ? 'Ada gambar' : 'Image',
                      color: AppTheme.info,
                      isDark: isDark,
                    ),
                  ),
                const Spacer(),
                Icon(
                  _showAdvanced
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TypeDropdown(
              value: widget.question.type,
              isDark: isDark,
              onChanged: _changeType,
            ),
          ),
          IconButton(
            tooltip: l10n.moveUp,
            onPressed: widget.onMoveUp,
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            color: AppTheme.textMuted,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: l10n.moveDown,
            onPressed: widget.onMoveDown,
            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
            color: AppTheme.textMuted,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: l10n.deleteQuestionTooltip,
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppTheme.error,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionImage(bool isDark) {
    final q = widget.question;
    final l10n = AppLocalizations.of(context);
    final hasImage = q.imageUrl != null && q.imageUrl!.isNotEmpty;
    final isDataUrl = hasImage && q.imageUrl!.startsWith('data:');
    Widget? thumb;
    if (hasImage) {
      try {
        thumb = isDataUrl
            ? Image.memory(base64Decode(q.imageUrl!.split(',').last),
                width: 44, height: 44, fit: BoxFit.cover)
            : Image.network(q.imageUrl!,
                width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, size: 20));
      } catch (_) {
        thumb = const Icon(Icons.broken_image_outlined, size: 20);
      }
    }
    // Button kompak (tidak melebar penuh) supaya halaman tetap rapi.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              onPressed: _pickQuestionImage,
              icon: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6), child: thumb!)
                  : Icon(Icons.add_photo_alternate_outlined,
                      size: 16, color: context.primary),
              label: Text(
                hasImage
                    ? (l10n.isIndonesian ? 'Ganti gambar' : 'Change image')
                    : (l10n.isIndonesian ? 'Gambar soal' : 'Question image'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.isIndonesian ? 'Hapus' : 'Remove',
                onPressed: _removeQuestionImage,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppTheme.error,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final showToolbar = _showFormatting || _editorFocused;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _editorFocused
              ? context.primaryWith(0.45)
              : (isDark ? AppTheme.darkBorder : AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Text(
                l10n.isIndonesian ? 'Pertanyaan / Teks Soal' : 'Question Text',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              // Toolbar formatting disembunyikan saat tidak menulis soal.
              // Guru cukup mengetuk kotak soal untuk memunculkannya.
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showFormatting = !showToolbar),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: showToolbar
                      ? context.primary
                      : (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                icon: Icon(
                  showToolbar
                      ? Icons.text_format_rounded
                      : Icons.format_color_text_rounded,
                  size: 16,
                ),
                label: Text(
                  showToolbar
                      ? (l10n.isIndonesian ? 'Tutup Format' : 'Hide Format')
                      : (l10n.isIndonesian ? 'Format Teks' : 'Formatting'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (showToolbar) ...[
            QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                multiRowsDisplay: false,
                toolbarSize: 22,
                showHeaderStyle: false,
                showFontFamily: false,
                showFontSize: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showSubscript: false,
                showSuperscript: false,
                showDirection: false,
                showSearchButton: false,
                showQuote: false,
                showIndent: false,
                showListCheck: false,
                showListBullets: true,
                showListNumbers: true,
                showAlignmentButtons: true,
                showLink: true,
                showCodeBlock: false,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showInlineCode: true,
                showUndo: true,
                showRedo: true,
                customButtons: [
                  QuillToolbarCustomButtonOptions(
                    icon: const Icon(Icons.image_outlined, size: 18),
                    tooltip: l10n.insertImageTooltip,
                    onPressed: _insertImage,
                  ),
                  QuillToolbarCustomButtonOptions(
                    icon: const Icon(Icons.functions_rounded, size: 18),
                    tooltip: l10n.insertMathTooltip,
                    onPressed: _insertMath,
                  ),
                  QuillToolbarCustomButtonOptions(
                    icon: const Icon(Icons.code_rounded, size: 18),
                    tooltip: l10n.insertCodeTooltip,
                    onPressed: _insertCode,
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: isDark ? AppTheme.darkBorder : AppTheme.border,
            ),
          ],
          QuillEditor(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: _scrollController,
            config: QuillEditorConfig(
              placeholder: l10n.writeQuestionHere,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              autoFocus: false,
              expands: false,
              scrollable: true,
              minHeight: 70,
              maxHeight: 180,
              embedBuilders: buildQuillEmbedBuilders(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(bool isDark) {
    final q = widget.question;
    final l10n = AppLocalizations.of(context);
    switch (q.type) {
      case QuestionType.multipleChoice:
      case QuestionType.checkbox:
        return [
          if (q.type == QuestionType.checkbox)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MiniBadge(
                icon: Icons.check_box_outlined,
                text: l10n.isIndonesian
                    ? 'Boleh lebih dari satu jawaban benar'
                    : 'Multiple correct answers allowed',
                color: context.primary,
                isDark: isDark,
              ),
            ),
          for (var i = 0; i < q.options.length; i++) ...[
            _OptionEditor(
              key: ValueKey('${q.type.name}_${q.options[i].id}'),
              option: q.options[i],
              isCorrect: q.options[i].isCorrect,
              multiSelect: q.type == QuestionType.checkbox,
              isDark: isDark,
              onTextChanged: (text) => _updateOptionText(i, text),
              onCorrectTap: () => _setCorrectOption(i),
              onDelete: q.options.length > 2
                  ? () => _removeOption(i)
                  : null,
            ),
            const SizedBox(height: 8),
          ],
          _buildAddOptionButton(isDark),
        ];
      case QuestionType.imageChoice:
        return [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.primaryWith(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.primaryWith(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.image_outlined, size: 14, color: context.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(l10n.isIndonesian ? 'Pilihan Gambar — tap gambar untuk upload, tap lingkaran untuk jawaban benar' : 'Image Choice — tap image to upload, tap circle for correct answer', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < q.options.length; i++) ...[
            _ImageOptionEditor(
              key: ValueKey(q.options[i].id),
              option: q.options[i],
              isCorrect: q.options[i].isCorrect,
              isDark: isDark,
              onTextChanged: (text) => _updateOptionText(i, text),
              onCorrectTap: () => _setCorrectOption(i),
              onPickImage: () => _pickOptionImage(i),
              onRemoveImage: () => _removeOptionImage(i),
              onDelete: q.options.length > 2 ? () => _removeOption(i) : null,
            ),
            const SizedBox(height: 10),
          ],
          _buildAddOptionButton(isDark),
        ];
      case QuestionType.yesNo:
        return [
          for (var i = 0; i < q.options.length; i++)
            _OptionEditor(
              key: ValueKey(q.options[i].id),
              option: q.options[i],
              isCorrect: q.options[i].isCorrect,
              isDark: isDark,
              onTextChanged: (text) => _updateOptionText(i, text),
              onCorrectTap: () => _setCorrectOption(i),
              onDelete: null,
            ),
        ];
      case QuestionType.rating:
        return [
          _buildRatingEditor(isDark),
        ];
      case QuestionType.shortText:
        return [
          _HintNote(
            icon: Icons.short_text_rounded,
            text: l10n.shortTextHintNote,
            isDark: isDark,
          ),
        ];
      case QuestionType.longText:
        return [
          _HintNote(
            icon: Icons.subject_rounded,
            text: l10n.longTextHintNote,
            isDark: isDark,
          ),
        ];
      case QuestionType.codeInput:
        return [
          _CodeField(
            key: ValueKey('code_${q.id}'),
            initial: q.codeSnippet ?? '',
            isDark: isDark,
            onChanged: _setCodeSnippet,
          ),
        ];
      case QuestionType.mathFormula:
        return [
          _HintNote(
            icon: Icons.functions_rounded,
            text: l10n.mathHintNote,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _MathField(
            key: ValueKey('math_${q.id}'),
            initial: q.mathFormula ?? '',
            isDark: isDark,
            onChanged: _setMathFormula,
          ),
        ];
      case QuestionType.matching:
        final pairs = q.matchingPairs.isEmpty
            ? [
                MatchingPair(
                  id: 'm${DateTime.now().microsecondsSinceEpoch}_0',
                  left: '',
                  right: '',
                ),
              ]
            : q.matchingPairs;
        return [
          _HintNote(
            icon: Icons.compare_arrows_rounded,
            text: l10n.matchingHintNote,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < pairs.length; i++) ...[
            _MatchingPairEditor(
              key: ValueKey(pairs[i].id),
              pair: pairs[i],
              isDark: isDark,
              canDelete: pairs.length > 2,
              onLeftChanged: (v) => _updateMatchingLeft(i, v),
              onRightChanged: (v) => _updateMatchingRight(i, v),
              onDelete: () => _removeMatchingPair(i),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _addMatchingPair,
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? const Color(0xFF4A90D9) : context.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  l10n.addPairLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ];
    }
  }

  Widget _buildAddOptionButton(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: _addOption,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFF4A90D9) : context.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            l10n.addOptionLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingEditor(bool isDark) {
    final q = widget.question;
    final l10n = AppLocalizations.of(context);
    final max = (q.ratingMax ?? 5).clamp(1, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.starsLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: max,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: [3, 5, 10]
                  .map(
                    (n) => DropdownMenuItem(value: n, child: Text('$n')),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) _setRatingMax(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.correctAnswerOptional,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: List.generate(max, (i) {
            final filled = q.correctRating == i + 1;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _setCorrectRating(i + 1),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: filled ? AppTheme.warning : AppTheme.textMuted,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRequiredRow(bool isDark) {
    final q = widget.question;
    final l10n = AppLocalizations.of(context);
    final isRequired = q.isRequired;
    final hasScore = q.hasScore;
    final score = q.score;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.requiredLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Switch(
              value: isRequired,
              onChanged: _toggleRequired,
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.stars_rounded,
              size: 16,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.assignPointsLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Switch(
              value: hasScore,
              onChanged: (val) {
                widget.onChanged(
                  _copy(q, hasScore: val, score: val ? (score > 0 ? score : 10) : 0),
                );
              },
            ),
          ],
        ),
        if (hasScore)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l10n.pointsMax100,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _PointsField(
                  key: ValueKey('points_${q.id}'),
                  value: score,
                  isDark: isDark,
                  onChanged: (val) {
                    widget.onChanged(_copy(q, score: val));
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _insertImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      String extension = 'png';
      final String path = image.path.toLowerCase();
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        extension = 'jpeg';
      } else if (path.endsWith('.gif')) {
        extension = 'gif';
      } else if (path.endsWith('.webp')) {
        extension = 'webp';
      }

      final String dataUrl = 'data:image/$extension;base64,$base64Image';

      int index = _controller.selection.baseOffset;
      if (index < 0) index = _controller.document.length - 1;
      if (index < 0) index = 0;

      _controller.replaceText(
        index,
        0,
        BlockEmbed.image(dataUrl),
        TextSelection.collapsed(offset: index + 1),
      );
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );

      _focusNode.requestFocus();
    } catch (_) {
      debugPrint('Image insertion error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToInsertImage)),
      );
    }
  }

  void _insertCode() {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.code_rounded),
              const SizedBox(width: 8),
              Text(l10n.insertCodeTitle),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: TextField(
              controller: controller,
              maxLines: 18,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: l10n.codePlaceholder,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.trimRight();
                Navigator.pop(dialogContext);
                if (code.isEmpty) return;

                int index = _controller.selection.baseOffset;
                if (index < 0) {
                  index = _controller.document.length - 1;
                }
                if (index < 0) index = 0;

                _controller.replaceText(
                  index,
                  0,
                  '$code\n',
                  TextSelection.collapsed(offset: index + code.length + 1),
                );
                _controller.formatText(
                  index,
                  code.length,
                  Attribute.codeBlock,
                );
                _controller.updateSelection(
                  TextSelection.collapsed(offset: index + code.length + 1),
                  ChangeSource.local,
                );

                _focusNode.requestFocus();
              },
              child: Text(l10n.insertLabel),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _insertMath() {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.functions_rounded),
                  const SizedBox(width: 8),
                  Text(l10n.mathFormulaTitle),
                ],
              ),
              content: SizedBox(
                width: 700,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: r'$\frac{a}{b} = x^2$',
                        helperText: r'Use $...$ or $$...$$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.previewLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildMathPreview(controller.text),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final raw = controller.text.trim();
                    if (raw.isEmpty) return;
                    Navigator.pop(dialogContext, cleanLatex(raw));
                  },
                  child: Text(l10n.insertFormulaLabel),
                ),
              ],
            );
          },
        );
      },
    ).then((formula) {
      if (formula == null || formula.isEmpty) return;

      int index = _controller.selection.baseOffset;
      if (index < 0) index = 0;
      if (index > _controller.document.length) {
        index = _controller.document.length;
      }

      final embed = BlockEmbed.custom(MathBlockEmbed(formula));
      _controller.replaceText(
        index,
        0,
        embed,
        TextSelection.collapsed(offset: index + 1),
      );
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );

      _focusNode.requestFocus();
    }).whenComplete(controller.dispose);
  }

  Widget _buildMathPreview(String input) {
    final l10n = AppLocalizations.of(context);
    final expression = cleanLatex(input);
    if (expression.isEmpty) {
      return Center(
        child: Text(
          l10n.enterLatexFormula,
          style: const TextStyle(fontSize: 13),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Math.tex(
        expression,
        onErrorFallback: (error) => Text(
          l10n.invalidLatexFormula,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.error,
          ),
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final QuestionType value;
  final bool isDark;
  final ValueChanged<QuestionType> onChanged;

  const _TypeDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<QuestionType>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
          items: QuestionType.values.map((t) {
            return DropdownMenuItem<QuestionType>(
              value: t,
              child: Row(
                children: [
                  Icon(
                    _icon(t),
                    size: 16,
                    color: isDark ? const Color(0xFF4A90D9) : context.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _label(t, l10n),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  String _label(QuestionType t, AppLocalizations l10n) {
    switch (t) {
      case QuestionType.multipleChoice:
        return l10n.qMultipleChoice;
      case QuestionType.checkbox:
        return l10n.qCheckbox;
      case QuestionType.shortText:
        return l10n.qShortAnswer;
      case QuestionType.longText:
        return l10n.qEssay;
      case QuestionType.rating:
        return l10n.qRating;
      case QuestionType.yesNo:
        return l10n.qYesNo;
      case QuestionType.imageChoice:
        return l10n.qImageChoice;
      case QuestionType.mathFormula:
        return l10n.qMathFormula;
      case QuestionType.codeInput:
        return l10n.qCodeInput;
      case QuestionType.matching:
        return l10n.qMatching;
    }
  }

  IconData _icon(QuestionType t) {
    switch (t) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.shortText:
        return Icons.short_text_rounded;
      case QuestionType.longText:
        return Icons.subject_rounded;
      case QuestionType.rating:
        return Icons.star_outline_rounded;
      case QuestionType.yesNo:
        return Icons.check_circle_outline;
      case QuestionType.imageChoice:
        return Icons.image_outlined;
      case QuestionType.mathFormula:
        return Icons.functions_rounded;
      case QuestionType.codeInput:
        return Icons.code_rounded;
      case QuestionType.checkbox:
        return Icons.check_box_outlined;
      case QuestionType.matching:
        return Icons.compare_arrows_rounded;
    }
  }
}

class _OptionEditor extends StatefulWidget {
  final OptionModel option;
  final bool isCorrect;

  /// `true` untuk soal kotak centang (boleh banyak jawaban benar) sehingga
  /// indikatornya berbentuk kotak centang, bukan bulatan pilihan tunggal.
  final bool multiSelect;
  final bool isDark;
  final void Function(String) onTextChanged;
  final VoidCallback onCorrectTap;
  final VoidCallback? onDelete;

  const _OptionEditor({
    super.key,
    required this.option,
    required this.isCorrect,
    this.multiSelect = false,
    required this.isDark,
    required this.onTextChanged,
    required this.onCorrectTap,
    this.onDelete,
  });

  @override
  State<_OptionEditor> createState() => _OptionEditorState();
}

class _OptionEditorState extends State<_OptionEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.option.text);
  }

  @override
  void didUpdateWidget(covariant _OptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.option.text != _controller.text) {
      _controller.text = widget.option.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: widget.onCorrectTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: widget.multiSelect ? BoxShape.rectangle : BoxShape.circle,
              borderRadius:
                  widget.multiSelect ? BorderRadius.circular(6) : null,
              color: widget.isCorrect
                  ? AppTheme.success
                  : Colors.transparent,
              border: Border.all(
                color: widget.isCorrect
                    ? AppTheme.success
                    : (widget.isDark ? AppTheme.darkBorder : AppTheme.border),
                width: 2,
              ),
            ),
            child: widget.isCorrect
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: widget.onTextChanged,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.optionTextHint,
              isDense: true,
              filled: true,
              fillColor:
                  widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? AppTheme.darkBorder
                      : AppTheme.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? AppTheme.darkBorder
                      : AppTheme.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? const Color(0xFF4A90D9)
                      : context.primary,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        if (widget.onDelete != null) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: l10n.deleteOptionTooltip,
            onPressed: widget.onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppTheme.textMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}

class _MatchingPairEditor extends StatefulWidget {
  final MatchingPair pair;
  final bool isDark;
  final bool canDelete;
  final void Function(String) onLeftChanged;
  final void Function(String) onRightChanged;
  final VoidCallback onDelete;

  const _MatchingPairEditor({
    super.key,
    required this.pair,
    required this.isDark,
    required this.canDelete,
    required this.onLeftChanged,
    required this.onRightChanged,
    required this.onDelete,
  });

  @override
  State<_MatchingPairEditor> createState() => _MatchingPairEditorState();
}

class _MatchingPairEditorState extends State<_MatchingPairEditor> {
  late final TextEditingController _leftController;
  late final TextEditingController _rightController;

  @override
  void initState() {
    super.initState();
    _leftController = TextEditingController(text: widget.pair.left);
    _rightController = TextEditingController(text: widget.pair.right);
  }

  @override
  void didUpdateWidget(covariant _MatchingPairEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pair.left != _leftController.text) {
      _leftController.text = widget.pair.left;
    }
    if (widget.pair.right != _rightController.text) {
      _rightController.text = widget.pair.right;
    }
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.isDark ? const Color(0xFF4A90D9) : context.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
    );
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _leftController,
            onChanged: widget.onLeftChanged,
            style: textStyle,
            decoration: _decoration(l10n.matchingLeftHint),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.compare_arrows_rounded, size: 18, color: AppTheme.textMuted),
        ),
        Expanded(
          child: TextField(
            controller: _rightController,
            onChanged: widget.onRightChanged,
            style: textStyle,
            decoration: _decoration(l10n.matchingRightHint),
          ),
        ),
        if (widget.canDelete) ...[
          const SizedBox(width: 2),
          IconButton(
            tooltip: l10n.deletePairTooltip,
            onPressed: widget.onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppTheme.textMuted,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}

class _ImageOptionEditor extends StatefulWidget {
  final OptionModel option;
  final bool isCorrect;
  final bool isDark;
  final void Function(String) onTextChanged;
  final VoidCallback onCorrectTap;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback? onDelete;

  const _ImageOptionEditor({
    super.key,
    required this.option,
    required this.isCorrect,
    required this.isDark,
    required this.onTextChanged,
    required this.onCorrectTap,
    required this.onPickImage,
    required this.onRemoveImage,
    this.onDelete,
  });

  @override
  State<_ImageOptionEditor> createState() => _ImageOptionEditorState();
}

class _ImageOptionEditorState extends State<_ImageOptionEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.option.text);
  }

  @override
  void didUpdateWidget(covariant _ImageOptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.option.text != _controller.text) _controller.text = widget.option.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasImage => widget.option.imageUrl != null && widget.option.imageUrl!.isNotEmpty;
  bool get _isDataUrl => _hasImage && widget.option.imageUrl!.startsWith('data:');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isCorrect ? AppTheme.success.withValues(alpha: 0.06) : (widget.isDark ? AppTheme.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isCorrect ? AppTheme.success : (widget.isDark ? AppTheme.darkBorder : AppTheme.border), width: widget.isCorrect ? 1.8 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onCorrectTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isCorrect ? AppTheme.success : Colors.transparent,
                    border: Border.all(color: widget.isCorrect ? AppTheme.success : (widget.isDark ? AppTheme.darkBorder : AppTheme.border), width: 2),
                  ),
                  child: widget.isCorrect ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.isCorrect ? (l10n.isIndonesian ? 'Jawaban Benar' : 'Correct Answer') : (l10n.isIndonesian ? 'Opsi Gambar' : 'Image Option'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.isCorrect ? AppTheme.success : (widget.isDark ? AppTheme.darkTextMuted : AppTheme.textMuted))),
              ),
              if (widget.onDelete != null)
                IconButton(tooltip: l10n.deleteOptionTooltip, onPressed: widget.onDelete, icon: const Icon(Icons.close_rounded, size: 18), color: AppTheme.textMuted, visualDensity: VisualDensity.compact),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: widget.onPickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 140,
                color: widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
                child: _hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _isDataUrl
                              ? Image.memory(base64Decode(widget.option.imageUrl!.split(',').last), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)))
                              : Image.network(widget.option.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined))),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: widget.onPickImage,
                                  child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white)),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: widget.onRemoveImage,
                                  child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: widget.isCorrect ? AppTheme.success : Colors.black54, borderRadius: BorderRadius.circular(8)),
                              child: Text(widget.isCorrect ? '✓ ${l10n.isIndonesian ? "Benar" : "Correct"}' : l10n.isIndonesian ? 'Tap lingkaran untuk benar' : 'Tap circle for correct', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 32, color: context.primaryWith(0.6)),
                          const SizedBox(height: 6),
                          Text(l10n.isIndonesian ? 'Tap untuk upload gambar' : 'Tap to upload image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primary)),
                          Text(l10n.isIndonesian ? 'JPG/PNG/WEBP maks 1 MB' : 'JPG/PNG/WEBP max 1 MB', style: TextStyle(fontSize: 12, color: widget.isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            onChanged: widget.onTextChanged,
            style: TextStyle(fontSize: 13, color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.isIndonesian ? 'Label opsi (opsional)' : 'Option label (optional)',
              isDense: true,
              filled: true,
              fillColor: widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.isDark ? AppTheme.darkBorder : AppTheme.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _HintNote({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge kecil (ikon + teks) untuk meringkas info penting pada kartu soal.
class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _MiniBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeField extends StatefulWidget {
  final String initial;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _CodeField({
    super.key,
    required this.initial,
    required this.isDark,
    required this.onChanged,
  });
  @override
  State<_CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<_CodeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _CodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != _controller.text) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      maxLines: 6,
      onChanged: widget.onChanged,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: l10n.starterCodeHint,
        filled: true,
        fillColor: widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _PointsField extends StatefulWidget {
  final double value;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _PointsField({
    super.key,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_PointsField> createState() => _PointsFieldState();
}

class _PointsFieldState extends State<_PointsField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.round().toString());
  }

  @override
  void didUpdateWidget(covariant _PointsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final parsed = double.tryParse(_controller.text);
    if (parsed == null || parsed != widget.value) {
      _controller.text = widget.value.round().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 36,
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
        onChanged: (val) {
          var s = double.tryParse(val) ?? 0;
          if (s > 100) s = 100;
          if (s < 0) s = 0;
          widget.onChanged(s);

          if (val.isNotEmpty && double.tryParse(val) != s) {
            _controller.text = s.round().toString();
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
          }
        },
      ),
    );
  }
}

class _MathField extends StatefulWidget {
  final String initial;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _MathField({
    super.key,
    required this.initial,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_MathField> createState() => _MathFieldState();
}

class _MathFieldState extends State<_MathField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _MathField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != _controller.text) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: r'$\frac{a}{b} = x^2$',
            helperText: r'Use $...$ or $$...$$',
            filled: true,
            fillColor:
                widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _buildPreview(),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final l10n = AppLocalizations.of(context);
    final expression = cleanLatex(_controller.text);
    if (expression.isEmpty) {
      return Text(
        l10n.previewPlaceholder,
        style: TextStyle(
          fontSize: 13,
          color: widget.isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Math.tex(
        expression,
        onErrorFallback: (error) => Text(
          l10n.invalidLatexFormula,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.error,
          ),
        ),
      ),
    );
  }
}
