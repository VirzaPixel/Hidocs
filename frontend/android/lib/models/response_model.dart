import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';

class ResponseModel {
  final String id;
  final String formId;
  final String formTitle;

  final String respondentId;
  final String respondentName;
  final String respondentEmail;

  final DateTime startedAt;
  final DateTime submittedAt;

  final Map<String, dynamic> answers;

  double score;
  final double maxScore;

  final Map<String, double> essayScores;
  final Map<String, double> autoScores;

  ResponseModel({
    required this.id,
    required this.formId,
    this.formTitle = '',
    required this.respondentName,
    required this.respondentEmail,
    required this.startedAt,
    required this.submittedAt,
    this.respondentId = '',
    Map<String, dynamic>? answers,
    this.score = 0,
    this.maxScore = 0,
    Map<String, double>? essayScores,
    Map<String, double>? autoScores,
  })  : answers = answers ?? {},
        essayScores = essayScores ?? {},
        autoScores = autoScores ?? {};

  Duration get duration =>
      submittedAt.difference(startedAt);

  int get durationInSeconds =>
      duration.inSeconds;

  String get durationText {
    final totalSeconds = durationInSeconds;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}j ${minutes}m ${seconds}d';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}d';
    }

    return '${seconds}d';
  }

  double get percentage {
    if (maxScore <= 0) return 0;

    final value = score / maxScore * 100;

    if (value < 0) return 0;
    if (value > 100) return 100;

    return value;
  }

  factory ResponseModel.fromApiJson(
    Map<String, dynamic> json, {
    FormModel? form,
  }) {
    final answers = <String, dynamic>{};
    final essayScores = <String, double>{};
    final autoScores = <String, double>{};

    final answerList = json['answers'];
    if (answerList is List) {
      for (final a in answerList.whereType<Map>()) {
        final qid = (a['question_id'] ?? '').toString();
        if (qid.isEmpty) continue;

        final selectedOptionID =
            (a['selected_option_id'] ?? '').toString();
        final answerText = (a['answer_text'] ?? '').toString();

        final isCheckbox =
            form?.questions.any((q) => q.id == qid && q.type == QuestionType.checkbox) ??
                false;

        if (selectedOptionID.isNotEmpty) {
          if (isCheckbox) {
            final existing = answers[qid];
            if (existing is Set<String>) {
              existing.add(selectedOptionID);
            } else {
              answers[qid] = <String>{selectedOptionID};
            }
          } else {
            answers[qid] = selectedOptionID;
          }
        } else if (answerText.isNotEmpty) {
          answers[qid] = answerText;
        } else {
          answers[qid] = '';
        }

        if (a['score_given'] is num) {
          final s = (a['score_given'] as num).toDouble();
          final isEssay =
              form?.questions.any((q) => q.id == qid && _isManuallyGraded(q.type)) ??
                  false;

          if (isEssay) {
            if (s != 0) {
              essayScores[qid] = s;
            }
          } else {
            autoScores[qid] = s;
          }
        }
      }
    }

    final email = (json['respondent_email'] ?? '').toString();
    final submittedAt =
        DateTime.tryParse(json['submitted_at']?.toString() ?? '')
                ?.toLocal() ??
            DateTime.now();

    final totalScore = (json['total_score'] is num)
        ? (json['total_score'] as num).toDouble()
        : 0.0;

    return ResponseModel(
      id: (json['id'] ?? '').toString(),
      formId: (json['form_id'] ?? '').toString(),
      formTitle: form?.title ?? (json['form_title'] ?? '').toString(),
      respondentName: nameFromEmail(email),
      respondentEmail: email,
      startedAt: submittedAt,
      submittedAt: submittedAt,
      answers: answers,
      score: totalScore,
      maxScore: form != null && form.maxScore > 0 ? form.maxScore : 0,
      essayScores: essayScores,
      autoScores: autoScores,
    );
  }

  factory ResponseModel.fromSubmission({
    required String formId,
    required String respondentId,
    required String respondentEmail,
    required Map<String, dynamic> answers,
    String formTitle = '',
    String responseId = '',
    double? totalScore,
    DateTime? submittedAt,
    double maxScore = 0,
  }) {
    final submitted = submittedAt ?? DateTime.now();

    return ResponseModel(
      id: responseId.isNotEmpty ? responseId : 'resp_$formId',
      formId: formId,
      formTitle: formTitle,
      respondentId: respondentId,
      respondentName: nameFromEmail(respondentEmail),
      respondentEmail: respondentEmail,
      startedAt: submitted,
      submittedAt: submitted,
      answers: answers,
      score: totalScore ?? 0,
      maxScore: maxScore,
    );
  }

  factory ResponseModel.fromStoredJson(Map<String, dynamic> json) {
    return ResponseModel(
      id: (json['id'] ?? '').toString(),
      formId: (json['form_id'] ?? '').toString(),
      formTitle: (json['form_title'] ?? '').toString(),
      respondentId: (json['respondent_id'] ?? '').toString(),
      respondentName: (json['respondent_name'] ?? '').toString(),
      respondentEmail: (json['respondent_email'] ?? '').toString(),
      startedAt:
          DateTime.tryParse(json['started_at']?.toString() ?? '') ??
              DateTime.now(),
      submittedAt:
          DateTime.tryParse(json['submitted_at']?.toString() ?? '') ??
              DateTime.now(),
      answers: json['answers'] is Map
          ? Map<String, dynamic>.from(json['answers'] as Map)
          : <String, dynamic>{},
      score: (json['score'] is num)
          ? (json['score'] as num).toDouble()
          : 0,
      maxScore: (json['max_score'] is num)
          ? ((json['max_score'] as num) > 0
              ? (json['max_score'] as num).toDouble()
              : 0)
          : 0,
      essayScores: _toDoubleMap(json['essay_scores']),
      autoScores: _toDoubleMap(json['auto_scores']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_id': formId,
      'form_title': formTitle,
      'respondent_id': respondentId,
      'respondent_name': respondentName,
      'respondent_email': respondentEmail,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt.toIso8601String(),
      'answers': answers,
      'score': score,
      'max_score': maxScore,
      'essay_scores': essayScores,
      'auto_scores': autoScores,
    };
  }

  ResponseModel copyWith({
    String? id,
    String? formId,
    String? formTitle,
    String? respondentId,
    String? respondentName,
    String? respondentEmail,
    DateTime? startedAt,
    DateTime? submittedAt,
    Map<String, dynamic>? answers,
    double? score,
    double? maxScore,
    Map<String, double>? essayScores,
    Map<String, double>? autoScores,
  }) {
    return ResponseModel(
      id: id ?? this.id,
      formId: formId ?? this.formId,
      formTitle: formTitle ?? this.formTitle,
      respondentId: respondentId ?? this.respondentId,
      respondentName:
          respondentName ?? this.respondentName,
      respondentEmail:
          respondentEmail ?? this.respondentEmail,
      startedAt:
          startedAt ?? this.startedAt,
      submittedAt:
          submittedAt ?? this.submittedAt,
      answers:
          answers ??
          Map<String, dynamic>.from(this.answers),
      score:
          score ?? this.score,
      maxScore:
          maxScore ?? this.maxScore,
      essayScores:
          essayScores ??
          Map<String, double>.from(
            this.essayScores,
          ),
      autoScores:
          autoScores ??
          Map<String, double>.from(
            this.autoScores,
          ),
    );
  }
}

bool _isManuallyGraded(QuestionType type) {
  return type == QuestionType.longText ||
      type == QuestionType.shortText ||
      type == QuestionType.codeInput ||
      type == QuestionType.mathFormula;
}

String nameFromEmail(String email) {
  final local = email.split('@').first.trim();
  if (local.isEmpty) return 'Responden';

  final parts = local
      .split(RegExp(r'[._\-+]'))
      .where((p) => p.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'Responden';

  final name = parts
      .map((p) =>
          p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join(' ');

  return name;
}

Map<String, double> _toDoubleMap(dynamic value) {
  if (value is! Map) return <String, double>{};

  return value.entries.fold<Map<String, double>>(
    <String, double>{},
    (acc, entry) {
      if (entry.value is num) {
        acc[entry.key.toString()] = (entry.value as num).toDouble();
      }
      return acc;
    },
  );
}
