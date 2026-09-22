import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/providers/form_provider.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<FormModel> _myForms = [];
  List<FormModel> _templates = [];
  bool _loadingMine = true;
  bool _loadingTemplates = true;
  final Map<String, List<QuestionModel>> _questionsCache = {};
  final Map<String, QuestionModel> _selected = {};
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fp = Provider.of<FormProvider>(context, listen: false);
    final mine = await fp.fetchMyForms();
    if (!mounted) return;
    setState(() {
      _myForms = mine;
      _loadingMine = false;
    });
    final templates = await fp.fetchTemplates();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _loadingTemplates = false;
    });
  }

  Future<List<QuestionModel>> _questionsOf(FormModel form) async {
    if (form.questions.isNotEmpty) return form.questions;
    if (_questionsCache.containsKey(form.id)) return _questionsCache[form.id]!;
    final fp = Provider.of<FormProvider>(context, listen: false);
    final qs = await fp.getQuestionsByForm(form.id);
    _questionsCache[form.id] = qs;
    return qs;
  }

  String _questionTitle(QuestionModel q) {
    final t = q.text.trim();
    if (t.isNotEmpty) return t;
    if (q.content != null && q.content!.trim().isNotEmpty) {
      return q.content!.trim().length > 80
          ? '${q.content!.trim().substring(0, 80)}...'
          : q.content!.trim();
    }
    return '—';
  }

  void _toggle(QuestionModel q) {
    setState(() {
      if (_selected.containsKey(q.id)) {
        _selected.remove(q.id);
      } else {
        _selected[q.id] = q;
      }
    });
  }

  List<QuestionModel> _clonedSelection() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    var i = 0;
    return _selected.values.map((q) {
      i++;
      return QuestionModel(
        id: 'q${ts}_$i',
        type: q.type,
        text: q.text,
        content: q.content,
        imageUrl: q.imageUrl,
        audioUrl: q.audioUrl,
        mathFormula: q.mathFormula,
        codeSnippet: q.codeSnippet,
        options: q.options
            .map((o) => OptionModel(
                  id: 'o${ts}_${i}_${o.id}',
                  text: o.text,
                  content: o.content,
                  imageUrl: o.imageUrl,
                  score: o.score,
                  isCorrect: o.isCorrect,
                ))
            .toList(),
        matchingPairs: List.of(q.matchingPairs),
        isRequired: q.isRequired,
        ratingMax: q.ratingMax,
        correctRating: q.correctRating,
        scoreVisibility: q.scoreVisibility,
        hasScore: q.hasScore,
        score: q.score,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.questionBank),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: l10n.tabMyForms),
            Tab(text: l10n.tabTemplates),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFormList(
                  isLoading: _loadingMine,
                  forms: _myForms,
                  emptyTitle: l10n.noFormsBank,
                  isDark: isDark,
                ),
                _buildFormList(
                  isLoading: _loadingTemplates,
                  forms: _templates,
                  emptyTitle: l10n.noTemplatesBank,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _clonedSelection()),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addToFormCount(_selected.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormList({
    required bool isLoading,
    required List<FormModel> forms,
    required String emptyTitle,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (forms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: forms.length,
      itemBuilder: (_, i) {
        final form = forms[i];
        final expanded = _expanded.contains(form.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            key: ValueKey(form.id),
            initiallyExpanded: expanded,
            onExpansionChanged: (v) {
              setState(() {
                if (v) {
                  _expanded.add(form.id);
                } else {
                  _expanded.remove(form.id);
                }
              });
            },
            title: Text(
              form.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: form.category.trim().isNotEmpty
                ? Text(form.category,
                    style: const TextStyle(fontSize: 12))
                : null,
            children: [
              FutureBuilder<List<QuestionModel>>(
                future: _questionsOf(form),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final qs = snap.data ?? [];
                  if (qs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noQuestionsInForm),
                    );
                  }
                  return Column(
                    children: [
                      for (final q in qs)
                        CheckboxListTile(
                          value: _selected.containsKey(q.id),
                          onChanged: (_) => _toggle(q),
                          title: Text(
                            _questionTitle(q),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '${q.type.name} • ${q.options.length} opsi',
                            style: const TextStyle(fontSize: 11),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
