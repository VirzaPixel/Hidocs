enum QuestionType {
  multipleChoice,
  checkbox,
  shortText,
  longText,
  rating,
  yesNo,
  imageChoice,
  mathFormula,
  codeInput,
  matching,
}

const String _codeStartMarker = '[CODE]';
const String _codeEndMarker = '[/CODE]';
const String _mathStartMarker = '[MATH]';
const String _mathEndMarker = '[/MATH]';

final RegExp _codeBlockPattern = RegExp(
  r'\[CODE\]\s*\n?([\s\S]*?)\s*\[\/CODE\]',
);
final RegExp _mathBlockPattern = RegExp(
  r'\[MATH\]\s*\n?([\s\S]*?)\s*\[\/MATH\]',
);

String encodeQuestionText(
  String text, {
  required String startMarker,
  required String endMarker,
  required String? payload,
}) {
  final clean = payload?.trim() ?? '';
  if (clean.isEmpty) return text.trimRight();

  final base = text.trimRight();
  return base.isEmpty
      ? '$startMarker\n$clean\n$endMarker'
      : '$base\n$startMarker\n$clean\n$endMarker';
}

String questionTypeToApi(QuestionType type) {
  switch (type) {
    case QuestionType.multipleChoice:
      return 'MULTIPLE_CHOICE';
    case QuestionType.shortText:
      return 'SHORT_TEXT';
    case QuestionType.longText:
      return 'LONG_TEXT';
    case QuestionType.rating:
      return 'RATING';
    case QuestionType.yesNo:
      return 'YES_NO';
    case QuestionType.imageChoice:
      return 'IMAGE';
    case QuestionType.checkbox:
      return 'CHECKBOXES';
    case QuestionType.mathFormula:
      return 'MATH';
    case QuestionType.codeInput:
      return 'CODE';
    case QuestionType.matching:
      return 'MATCHING';
  }
}

QuestionType questionTypeFromApi(String value) {
  switch (value) {
    case 'SHORT_TEXT':
      return QuestionType.shortText;
    case 'LONG_TEXT':
      return QuestionType.longText;
    case 'MULTIPLE_CHOICE':
    case 'DROPDOWN':
      return QuestionType.multipleChoice;
    case 'CHECKBOXES':
      return QuestionType.checkbox;
    case 'MATCHING':
      return QuestionType.matching;
    case 'RATING':
      return QuestionType.rating;
    case 'YES_NO':
      return QuestionType.yesNo;
    case 'MATH':
      return QuestionType.mathFormula;
    case 'CODE':
      return QuestionType.codeInput;
    case 'IMAGE':
      return QuestionType.imageChoice;
    default:
      return QuestionType.shortText;
  }
}

enum ScoreVisibility {
  hidden,
  visible,
}

class MatchingPair {
  final String id;
  final String left;
  final String right;

  const MatchingPair({
    required this.id,
    required this.left,
    required this.right,
  });

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      id: (json['id'] ?? '').toString(),
      left: (json['option_text'] ?? '').toString(),
      right: (json['match_text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson({int orderIndex = 1}) {
    return {
      'option_text': left,
      'match_text': right,
      'order_index': orderIndex,
    };
  }
}

class QuestionModel {
  final String id;
  final QuestionType type;
  String text;
  String? content;
  String? imageUrl;
  String? audioUrl;
  String? mathFormula;
  String? codeSnippet;
  List<OptionModel> options;
  List<MatchingPair> matchingPairs;
  bool isRequired;
  int? ratingMax;
  int? correctRating;

  ScoreVisibility scoreVisibility;
  bool hasScore;
  double score;

  QuestionModel({
    required this.id,
    required this.type,
    required this.text,
    this.content,
    this.imageUrl,
    this.audioUrl,
    this.mathFormula,
    this.codeSnippet,
    List<OptionModel>? options,
    List<MatchingPair>? matchingPairs,
    this.isRequired = true,
    this.ratingMax,
    this.correctRating,
    this.scoreVisibility = ScoreVisibility.hidden,
    this.hasScore = false,
    this.score = 0,
  })  : options = options ?? [],
        matchingPairs = matchingPairs ?? [];

  /// Whether this question type CAN participate in scoring at all.
  /// Rating is purely a survey/feedback type — it is NEVER counted towards
  /// a form's total score or a respondent's percentage.
  bool get isScorable => type != QuestionType.rating;

  /// Whether this question is auto-scored (i.e. has correct answers set
  /// by the creator and a non-zero point value, and is not manually graded).
  bool get isAutoScorable {
    // Manually-graded types are never auto-scored
    const manualTypes = {
      QuestionType.longText,
      QuestionType.shortText,
      QuestionType.codeInput,
      QuestionType.mathFormula,
    };
    return isScorable && !manualTypes.contains(type) && (hasScore || score > 0);
  }

  QuestionModel copyWith({
    String? text,
    String? content,
    String? imageUrl,
    String? audioUrl,
    String? mathFormula,
    String? codeSnippet,
    List<OptionModel>? options,
    List<MatchingPair>? matchingPairs,
    bool? isRequired,
    int? ratingMax,
    int? correctRating,
    ScoreVisibility? scoreVisibility,
    bool? hasScore,
    double? score,
  }) {
    return QuestionModel(
      id: id,
      type: type,
      text: text ?? this.text,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      mathFormula: mathFormula ?? this.mathFormula,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      options: options ?? this.options,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      isRequired: isRequired ?? this.isRequired,
      ratingMax: ratingMax ?? this.ratingMax,
      correctRating: correctRating ?? this.correctRating,
      scoreVisibility: scoreVisibility ?? this.scoreVisibility,
      hasScore: hasScore ?? this.hasScore,
      score: score ?? this.score,
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final questionId = (json['id'] ?? '').toString();
    final imageUrl = (json['img_url'] ?? '').toString();
    final audioUrl = (json['audio_url'] ?? '').toString();
    final codeLanguage = (json['code_language'] ?? '').toString();

    QuestionType mappedType =
        questionTypeFromApi((json['question_type'] ?? '').toString());

    String? snippet;
    if (mappedType == QuestionType.codeInput && codeLanguage.isNotEmpty) {
      snippet = codeLanguage;
    }

    var rawText = (json['question_text'] ?? '').toString();

    final codeMatch = _codeBlockPattern.firstMatch(rawText);
    if (codeMatch != null) {
      final payload = codeMatch.group(1)?.trim() ?? '';
      if (payload.isNotEmpty) snippet = payload;
      rawText = rawText.replaceRange(codeMatch.start, codeMatch.end, '');
    }

    String? mathFormula;
    final mathMatch = _mathBlockPattern.firstMatch(rawText);
    if (mathMatch != null) {
      final payload = mathMatch.group(1)?.trim() ?? '';
      if (payload.isNotEmpty) mathFormula = payload;
      rawText = rawText.replaceRange(mathMatch.start, mathMatch.end, '');
    }

    rawText = rawText.trim();

    final List<OptionModel> options = [];
    final List<MatchingPair> matchingPairs = [];
    if (json['options'] is List) {
      if (mappedType == QuestionType.matching) {
        matchingPairs.addAll((json['options'] as List)
            .whereType<Map>()
            .map((e) => MatchingPair.fromJson({...e})));
      } else {
        options.addAll((json['options'] as List)
            .whereType<Map>()
            .map((e) => OptionModel.fromJson({...e})));
      }
    }

    return QuestionModel(
      id: questionId,
      type: mappedType,
      text: rawText,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      audioUrl: audioUrl.isEmpty ? null : audioUrl,
      codeSnippet: snippet,
      mathFormula:
          mappedType == QuestionType.mathFormula ? mathFormula : null,
      isRequired: json['is_required'] == true,
      ratingMax: mappedType == QuestionType.rating ? 5 : null,
      hasScore: json['points'] is num && (json['points'] as num) > 0,
      score: (json['points'] is num) ? (json['points'] as num).toDouble() : 0,
      options: options,
      matchingPairs: matchingPairs,
    );
  }

  Map<String, dynamic> toQuestionJson({int orderIndex = 1}) {
    String questionText;
    switch (type) {
      case QuestionType.codeInput:
        questionText = encodeQuestionText(
          text,
          startMarker: _codeStartMarker,
          endMarker: _codeEndMarker,
          payload: codeSnippet,
        );
      case QuestionType.mathFormula:
        questionText = encodeQuestionText(
          text,
          startMarker: _mathStartMarker,
          endMarker: _mathEndMarker,
          payload: mathFormula,
        );
      default:
        questionText = text;
    }

    return {
      'question_text': questionText.trim().isEmpty
          ? (text.trim().isEmpty ? '.' : text)
          : questionText,
      'question_type': questionTypeToApi(type),
      'img_url': imageUrl,
      'is_auto_scored': hasScore,
      'points': hasScore ? score.round().clamp(0, 100) : 0,
      'order_index': orderIndex,
      'is_required': isRequired,
      'options': type == QuestionType.matching
          ? matchingPairs
              .asMap()
              .entries
              .map((e) => e.value.toJson(orderIndex: e.key + 1))
              .toList()
          : options
              .asMap()
              .entries
              .map((e) => e.value.toOptionJson(orderIndex: e.key + 1))
              .toList(),
    };
  }
}

class OptionModel {
  final String id;
  String text;
  String? content;
  String? imageUrl;

  double score;
  bool isCorrect;

  OptionModel({
    required this.id,
    required this.text,
    this.content,
    this.imageUrl,
    this.score = 0,
    this.isCorrect = false,
  });

  OptionModel copyWith({
    String? text,
    String? content,
    String? imageUrl,
    double? score,
    bool? isCorrect,
  }) {
    return OptionModel(
      id: id,
      text: text ?? this.text,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      score: score ?? this.score,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    final imageUrl = (json['img_url'] ?? '').toString();
    final isCorrect = json['is_correct'] == true;

    return OptionModel(
      id: (json['id'] ?? '').toString(),
      text: (json['option_text'] ?? '').toString(),
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      score: isCorrect ? 1 : 0,
      isCorrect: isCorrect,
    );
  }

  Map<String, dynamic> toOptionJson({int orderIndex = 1}) {
    final map = <String, dynamic>{
      'option_text': text,
      'is_correct': isCorrect || score > 0,
      'order_index': orderIndex,
    };    if (imageUrl != null && imageUrl!.isNotEmpty) {
      map['img_url'] = imageUrl;
      // fallback: encode image as dataUrl in text if backend doesn't persist img_url
      // keep option_text as is, backend may ignore img_url
    }
    return map;
  }
}