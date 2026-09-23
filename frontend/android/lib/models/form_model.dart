import 'package:hi_docs/models/question_model.dart';

enum ResultVisibility {
  hidden,
  resultOnly,
  resultAndScore,
}

enum FormType {
  survey,
  exam,
}

class FormModel {
  final String id;
  final String title;
  final String creatorId;
  final FormType formType;
  final String category;
  final bool isTemplate;

  final String shortLink;
  final String customLinkAlias;
  final String accessToken;
  final String examToken;
  final bool isTokenProtected;

  final DateTime scheduledOpen;
  final DateTime scheduledClose;

  final int timerMinutes;

  final bool isPublic;

  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool oneTimeOnly;
  final String themeColor;
  final int coverGradient;
  final bool _rawIsActive;

  final ResultVisibility resultVisibility;

  final List<QuestionModel> questions;

  final int totalResponses;
  final DateTime createdAt;

  FormModel({
    required this.id,
    required this.title,
    required this.creatorId,
    this.formType = FormType.survey,
    this.category = '',
    this.isTemplate = false,
    this.shortLink = '',
    this.customLinkAlias = '',
    this.accessToken = '',
    this.examToken = '',
    this.isTokenProtected = false,
    required this.scheduledOpen,
    required this.scheduledClose,
    this.timerMinutes = 0,
    this.isPublic = true,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
    this.oneTimeOnly = true,
    this.themeColor = '#4F46E5',
    this.coverGradient = 0,
    bool isActive = true,
    this.resultVisibility = ResultVisibility.hidden,
    List<QuestionModel>? questions,
    this.totalResponses = 0,
    required this.createdAt,
  })  : _rawIsActive = isActive,
        questions = questions ?? [];

  bool get rawIsActive => _rawIsActive;

  bool get isExpired => isScheduled && DateTime.now().isAfter(scheduledClose);

  bool get isActive {
    if (!_rawIsActive) return false;
    if (isScheduled && DateTime.now().isAfter(scheduledClose)) {
      return false;
    }
    return true;
  }

  String get fullLink => customLinkAlias.isNotEmpty
      ? 'hidocs.app/f/$customLinkAlias'
      : 'hidocs.app/f/$shortLink';

  String get slug => customLinkAlias.isNotEmpty ? customLinkAlias : shortLink;

  bool get hasAccessToken =>
      accessToken.trim().isNotEmpty;

  bool get hasExamToken => examToken.trim().isNotEmpty;

  bool get requiresExamToken =>
      isExam && isTokenProtected && hasExamToken;

  double get maxScore {
    var total = 0.0;
    for (final q in questions) {
      if (!q.isScorable) continue;
      if (q.hasScore || q.score > 0) {
        total += q.score;
      } else if (q.type == QuestionType.longText ||
          q.type == QuestionType.shortText ||
          q.type == QuestionType.codeInput ||
          q.type == QuestionType.mathFormula) {
        // Essay/manual tanpa poin tetap dihitung 10 poin agar manual grading
        // bisa dinilai. Tanpa fallback ini maxScore=0 sehingga clamp di
        // response_detail mengunci total ke 0 dan essai terlihat gak bisa di-grade.
        total += 10;
      }
    }
    return total;
  }

  bool get isScheduled =>
      scheduledOpen != scheduledClose;

  bool get hasTimer =>
      timerMinutes > 0;

  bool get isExam => formType == FormType.exam || hasTimer || typeForApi == 'EXAM';
  bool get isSurvey => !isExam;

  Duration get scheduleDuration =>
      scheduledClose.difference(scheduledOpen);

  String get typeForApi => (formType == FormType.exam || hasTimer) ? 'EXAM' : 'SURVEY';

  factory FormModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> settings =
        json['form_settings'] is Map
            ? Map<String, dynamic>.from(json['form_settings'] as Map)
            : {};

    final startTime =
        DateTime.tryParse(settings['start_time']?.toString() ?? '')?.toLocal();
    final endTime =
        DateTime.tryParse(settings['end_time']?.toString() ?? '')?.toLocal();

    final now = DateTime.now();
    final defaultOpen = now;
    final defaultClose = now.add(const Duration(days: 1));

    final rawStatus = (json['status'] ?? settings['status'] ?? '').toString().toUpperCase();
    final dynamic isActiveVal = json['is_active'] ?? settings['is_active'];
    
    bool parsedIsActive = true;
    if (isActiveVal is bool) {
      parsedIsActive = isActiveVal;
    } else if (rawStatus == 'CLOSED' || rawStatus == 'INACTIVE' || rawStatus == 'FALSE' || rawStatus == '0') {
      parsedIsActive = false;
    } else if (isActiveVal == false || isActiveVal == 0 || isActiveVal == 'false' || isActiveVal == '0') {
      parsedIsActive = false;
    }

    final accessMode = (json['access_mode'] ??
            settings['access_mode'] ??
            'public')
        .toString();

    final isPublic = accessMode == 'public';

    final accessToken =
        (settings['access_token'] ?? json['access_token'] ?? '').toString();

    final examToken =
        (settings['exam_token'] ?? json['exam_token'] ?? '').toString();
    final isTokenProtected =
        settings['is_token_protected'] == true ||
        json['is_token_protected'] == true;

    final rawType = (json['type'] ?? settings['type'] ?? '').toString().toUpperCase();
    final parsedDuration = settings['duration_minutes'] is num
        ? ((settings['duration_minutes'] as num).toInt()).clamp(0, 100000)
        : 0;

    final rawResultVisibility =
        (settings['result_visibility'] ?? 'hidden').toString();
    final parsedResultVisibility = rawResultVisibility == 'result_and_score'
        ? ResultVisibility.resultAndScore
        : rawResultVisibility == 'result_only'
            ? ResultVisibility.resultOnly
            : ResultVisibility.hidden;

    final parsedFormType = (rawType == 'EXAM' || parsedDuration > 0)
        ? FormType.exam
        : FormType.survey;

    final parsedThemeColor =
        (settings['theme_color'] ?? json['theme_color'] ?? '#4F46E5')
            .toString();
    final parsedCoverGradient = settings['cover_gradient'] is num
        ? (settings['cover_gradient'] as num).toInt().clamp(0, 3)
        : 0;

    return FormModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      creatorId: (json['user_id'] ?? '').toString(),
      formType: parsedFormType,
      category: (json['category'] ?? '').toString(),
      isTemplate: json['is_template'] == true,
      shortLink: (json['custom_url'] ?? '').toString(),
      customLinkAlias: (json['custom_url'] ?? '').toString(),
      accessToken: accessToken,
      examToken: examToken,
      isTokenProtected: isTokenProtected,
      scheduledOpen: startTime ?? defaultOpen,
      scheduledClose: endTime ?? defaultClose,
      timerMinutes: parsedDuration,
      isPublic: isPublic,
      shuffleQuestions: settings['randomize_questions'] == true,
      shuffleOptions: settings['randomize_options'] == true,
      oneTimeOnly: settings['is_one_time_submission'] == true,
      themeColor: parsedThemeColor.isEmpty ? '#4F46E5' : parsedThemeColor,
      coverGradient: parsedCoverGradient,
      isActive: parsedIsActive,
      resultVisibility: parsedResultVisibility,
      questions: json['questions'] is List
          ? (json['questions'] as List)
                .whereType<Map>()
                .map((e) => QuestionModel.fromJson({...e}))
                .toList()
          : <QuestionModel>[],
      totalResponses: (json['response_count'] is num)
          ? (json['response_count'] as num).toInt()
          : 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }

  FormModel withCustomUrl(String slug) {
    return FormModel(
      id: id,
      title: title,
      creatorId: creatorId,
      formType: formType,
      category: category,
      isTemplate: isTemplate,
      shortLink: slug,
      customLinkAlias: slug,
      accessToken: accessToken,
      examToken: examToken,
      isTokenProtected: isTokenProtected,
      scheduledOpen: scheduledOpen,
      scheduledClose: scheduledClose,
      timerMinutes: timerMinutes,
      isPublic: isPublic,
      shuffleQuestions: shuffleQuestions,
      shuffleOptions: shuffleOptions,
      oneTimeOnly: oneTimeOnly,
      themeColor: themeColor,
      coverGradient: coverGradient,
      isActive: isActive,
      resultVisibility: resultVisibility,
      questions: questions,
      totalResponses: totalResponses,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': '',
      'category': category,
      'type': typeForApi,
      'custom_url': customLinkAlias.isEmpty ? shortLink : customLinkAlias,
      'access_mode': isPublic ? 'public' : 'qr-only',
      'show_in_user_list': isPublic,
      'qr_only': !isPublic,
      'is_template': false,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': '',
      'category': category,
      'type': typeForApi,
      'custom_url': customLinkAlias.isEmpty ? shortLink : customLinkAlias,
      'access_mode': isPublic ? 'public' : 'qr-only',
      'show_in_user_list': isPublic,
      'qr_only': !isPublic,
      'status': isActive ? 'ACTIVE' : 'CLOSED',
      'is_template': false,
    };
  }

  Map<String, dynamic> toSettingsJson() {
    final bool hasSchedule = isScheduled && scheduledClose.isAfter(scheduledOpen);
    return {
      'type': typeForApi,
      'duration_minutes': hasTimer ? timerMinutes : null,
      'auto_active_days': 30,
      'is_active_immediately': true,
      'is_one_time_submission': oneTimeOnly,
      'randomize_questions': shuffleQuestions,
      'randomize_options': shuffleOptions,
      'start_time': hasSchedule ? scheduledOpen.toUtc().toIso8601String() : null,
      'end_time': hasSchedule ? scheduledClose.toUtc().toIso8601String() : null,
      'theme_color': themeColor,
      'cover_gradient': coverGradient,
      'exam_token': examToken.trim().isEmpty ? null : examToken.trim(),
      'is_token_protected': isTokenProtected,
      'result_visibility': resultVisibility == ResultVisibility.resultAndScore
          ? 'result_and_score'
          : resultVisibility == ResultVisibility.resultOnly
              ? 'result_only'
              : 'hidden',
    };
  }
}

FormModel copyFormModel(
  FormModel source, {
  FormType? formType,
  bool? isPublic,
  bool? isActive,
  ResultVisibility? resultVisibility,
  String? themeColor,
  int? coverGradient,
  String? examToken,
  bool? isTokenProtected,
  String? category,
  bool? isTemplate,
}) {
  return FormModel(
    id: source.id,
    title: source.title,
    creatorId: source.creatorId,
    formType: formType ?? source.formType,
    category: category ?? source.category,
    isTemplate: isTemplate ?? source.isTemplate,
    shortLink: source.shortLink,
    customLinkAlias: source.customLinkAlias,
    accessToken: source.accessToken,
    examToken: examToken ?? source.examToken,
    isTokenProtected: isTokenProtected ?? source.isTokenProtected,
    scheduledOpen: source.scheduledOpen,
    scheduledClose: source.scheduledClose,
    timerMinutes: source.timerMinutes,
    isPublic: isPublic ?? source.isPublic,
    shuffleQuestions: source.shuffleQuestions,
    shuffleOptions: source.shuffleOptions,
    oneTimeOnly: source.oneTimeOnly,
    themeColor: themeColor ?? source.themeColor,
    coverGradient: coverGradient ?? source.coverGradient,
    isActive: isActive ?? source.rawIsActive,
    resultVisibility:
        resultVisibility ?? source.resultVisibility,
    questions: source.questions,
    totalResponses: source.totalResponses,
    createdAt: source.createdAt,
  );
}