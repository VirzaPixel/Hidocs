import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/services/api/api_client.dart';

class ResponseProvider extends ChangeNotifier {
  static const _storageKey = 'my_submissions';

  final List<ResponseModel> _responses = [];
  final Set<String> _submissionIds = {};

  bool _isLoading = false;
  String? _error;

  ResponseProvider() {
    _loadSubmissions();
  }

  List<ResponseModel> get responses => List.unmodifiable(_responses);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ResponseModel> getResponsesByRespondent(String respondentId) =>
      _responses.where((r) => r.respondentId == respondentId).toList();

  ResponseModel? getResponse(String id) {
    for (final r in _responses) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> _loadSubmissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_storageKey) ?? [];

      for (final raw in stored) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          final submission = ResponseModel.fromStoredJson(map);
          _responses.add(submission);
          _submissionIds.add(submission.id);
        } catch (_) {}
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSubmissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = _responses
          .where((r) => _submissionIds.contains(r.id))
          .map((r) => jsonEncode(r.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, stored);
    } catch (_) {}
  }

  List<ResponseModel> getResponsesByForm(String formId) =>
      _responses.where((r) => r.formId == formId).toList();

  Future<void> loadMySubmissions({dynamic formProvider}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.get('/responses/me');
      final list = data is List
          ? data
          : (data is Map && data['submissions'] is List
              ? data['submissions'] as List
              : const []);
      for (final raw in list.whereType<Map>()) {
        try {
          final map = Map<String, dynamic>.from(raw);
          final submission = ResponseModel.fromApiJson(map,
              form: formProvider?.getFormById?.call(
                      (map['form_id'] ?? '').toString()));
          _responses.removeWhere((r) => r.id == submission.id);
          _responses.add(submission);
          _submissionIds.add(submission.id);
        } catch (_) {}
      }
      await _saveSubmissions();
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadResponsesForForm(String formId,
      {dynamic form}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.get('/forms/$formId/responses');
      if (data is List) {
        for (final raw in data.whereType<Map>()) {
          try {
            final map = Map<String, dynamic>.from(raw);
            final submission = ResponseModel.fromStoredJson(map);
            _responses.removeWhere((r) => r.id == submission.id);
            _responses.add(submission);
            _submissionIds.add(submission.id);
          } catch (_) {}
        }
        await _saveSubmissions();
      }
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void removeResponsesByForm(String formId) {
    _responses.removeWhere((r) => r.formId == formId);
    _saveSubmissions();
    notifyListeners();
  }

  Future<void> saveGrade(String responseId, double total) async {
    final idx = _responses.indexWhere((r) => r.id == responseId);
    if (idx < 0) return;

    final sub = _responses[idx];
    _responses[idx] = sub.copyWith(score: total);

    // Kirim ke server API
    try {
      await ApiClient.saveResponseGrade(
        formId: sub.formId,
        responseId: responseId,
        totalScore: total,
      );
    } on ApiException catch (e) {
      // Log error tapi tetap simpan lokal sebagai fallback
      debugPrint('Grade API save failed: ${e.message}');
    }

    await _saveSubmissions();
    notifyListeners();
  }

  void rememberGrades(String responseId, Map<String, double> essayScores) {
    final idx = _responses.indexWhere((r) => r.id == responseId);
    if (idx < 0) return;

    _responses[idx] = _responses[idx].copyWith(
      essayScores: Map<String, double>.from(essayScores),
    );

    _saveSubmissions();
    notifyListeners();
  }

  void updateResponse(ResponseModel updated) {
    final index = _responses.indexWhere((r) => r.id == updated.id);
    if (index >= 0) {
      _responses[index] = updated;
    } else {
      _responses.add(updated);
    }
    _saveSubmissions();
    notifyListeners();
  }

  void recordSubmission({
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
    _responses.removeWhere(
      (r) => r.formId == formId && r.respondentId == respondentId,
    );

    _responses.add(
      ResponseModel.fromSubmission(
        formId: formId,
        respondentId: respondentId,
        respondentEmail: respondentEmail,
        answers: answers,
        formTitle: formTitle,
        responseId: responseId,
        totalScore: totalScore,
        submittedAt: submittedAt,
        maxScore: maxScore,
      ),
    );

    _submissionIds.add(
      responseId.isNotEmpty ? responseId : 'resp_$formId',
    );

    _saveSubmissions();
    notifyListeners();
  }
}
