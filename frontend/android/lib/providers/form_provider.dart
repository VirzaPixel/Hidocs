import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/services/api/api_client.dart';

class FormProvider extends ChangeNotifier {
  final List<FormModel> _forms = [];
  final Set<String> _submittedForms = {};
  bool _isLoading = false;
  String? _error;

  List<FormModel> get forms => List.unmodifiable(_forms);
  bool get isLoading => _isLoading;
  String? get error => _error;

  FormProvider() {
    _loadSubmitted();
  }

  Future<void> _loadSubmitted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('submitted_forms') ?? [];
      _submittedForms.addAll(ids);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSubmitted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('submitted_forms', _submittedForms.toList());
    } catch (_) {}
  }

  bool hasSubmitted(String formId) => _submittedForms.contains(formId);

  void markSubmitted(String formId) {
    _submittedForms.add(formId);
    _saveSubmitted();
    notifyListeners();
  }

  Future<FormModel?> loadFormDetail(String formId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.get('/forms/$formId');

      if (data is Map) {
        final detail = FormModel.fromJson(Map<String, dynamic>.from(data));

        final index = _forms.indexWhere((f) => f.id == detail.id);
        if (index >= 0) {
          _forms[index] = detail;
        } else {
          _forms.add(detail);
        }

        _isLoading = false;
        notifyListeners();

        return detail;
      }

      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
      _isLoading = false;
    }

    notifyListeners();
    return null;
  }

  Future<FormModel?> loadPublicForm(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.get(
        '/public/forms/${Uri.encodeComponent(code)}',
      );

      if (data is Map) {
        final form = FormModel.fromJson(Map<String, dynamic>.from(data));

        final index = _forms.indexWhere((f) => f.id == form.id);
        if (index >= 0) {
          _forms[index] = form;
        } else {
          _forms.add(form);
        }

        _isLoading = false;
        notifyListeners();

        return form;
      }

      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
      _isLoading = false;
    }

    notifyListeners();
    return null;
  }

  FormModel? getFormById(String formId) {
    final index = _forms.indexWhere((f) => f.id == formId);
    return index >= 0 ? _forms[index] : null;
  }

  Future<bool> verifyFormToken(String slug, String token) async {
    try {
      final data = await ApiClient.post(
        '/public/forms/${Uri.encodeComponent(slug)}/verify-token',
        body: {'token': token},
      );
      return data is Map &&
          (data['response_id'] != null || data['valid'] == true);
    } catch (_) {
      return false;
    }
  }

  List<FormModel> _toFormList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => FormModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<FormModel>> fetchMyForms({String? status}) async {
    try {
      final data = await ApiClient.get(
        '/forms',
        query: status != null ? {'status': status} : null,
      );
      return _toFormList(data);
    } catch (_) {
      return [];
    }
  }

  Future<List<FormModel>> fetchTemplates() async {
    try {
      final data = await ApiClient.get('/forms/templates');
      return _toFormList(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        try {
          final data2 = await ApiClient.get('/forms', query: {'is_template': 'true'});
          final list = _toFormList(data2);
          if (list.isNotEmpty) return list.where((f) => f.isTemplate).toList().isNotEmpty ? list.where((f) => f.isTemplate).toList() : list;
          return list;
        } catch (_) {
          return [];
        }
      }
      return [];
    } catch (_) {
      try {
        final data2 = await ApiClient.get('/forms', query: {'is_template': 'true'});
        return _toFormList(data2);
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<QuestionModel>> getQuestionsByForm(String formId) async {
    try {
      final data = await ApiClient.get('/forms/$formId/questions');
      if (data is List) {
        return data.whereType<Map>().map((e) => QuestionModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (data is Map && data['questions'] is List) {
        return (data['questions'] as List).whereType<Map>().map((e) => QuestionModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (data is Map) {
        final fm = FormModel.fromJson(Map<String, dynamic>.from(data));
        if (fm.questions.isNotEmpty) return fm.questions;
      }
      return [];
    } catch (_) {
      try {
        final detail = await loadFormDetail(formId);
        return detail?.questions ?? [];
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<String>> fetchCategories() async {
    try {
      final data = await ApiClient.get('/forms/categories');
      if (data is List) {
        return data.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
      }
      if (data is Map && data['categories'] is List) {
        return (data['categories'] as List).map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> verifyExamToken({
    required String formId,
    required String token,
    required String email,
  }) async {
    try {
      final data = await ApiClient.post(
        '/public/forms/${Uri.encodeComponent(formId)}/verify-token',
        body: {'token': token, 'respondent_email': email},
      );
      return data is Map;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> submitForm(
    String formId, {
    required String respondentEmail,
    required List<Map<String, dynamic>> answers,
    bool auto = false,
    String token = '',
    String responseId = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.post('/forms/$formId/submit', body: {
        'respondent_email': respondentEmail,
        'passcode': '',
        'token': token,
        'is_auto_submitted': auto,
        'answers': answers,
        if (responseId.isNotEmpty) 'response_id': responseId,
        if (ApiClient.examSessionToken != null &&
            ApiClient.examSessionToken!.isNotEmpty)
          'session_token': ApiClient.examSessionToken,
      });

      markSubmitted(formId);

      _isLoading = false;
      notifyListeners();

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();

    return null;
  }

  void clearError() {
    _error = null;
  }

  Future<void> loadForms({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.get('/forms');
      if (data is List) {
        _forms
          ..clear()
          ..addAll((data)
              .whereType<Map>()
              .map((e) => FormModel.fromJson({...e})));
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void syncExpiredForms() {
    _forms.removeWhere((f) => f.isExpired);
    notifyListeners();
  }

  List<FormModel> getFormsByCreator(String creatorId) =>
      _forms.where((f) => f.creatorId == creatorId).toList();

  Future<FormModel?> importExcel({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    return _importFile(
      path: '/forms/import-excel',
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  Future<FormModel?> importDocx({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    return _importFile(
      path: '/forms/import-docx',
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  Future<FormModel?> _importFile({
    required String path,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.uploadFile(
        path,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName ?? 'import',
      );
      FormModel? created;
      if (data is Map) {
        created = FormModel.fromJson(Map<String, dynamic>.from(data));
        _forms.add(created);
      }
      _isLoading = false;
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> deleteForm(String formId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiClient.delete('/forms/$formId');
      _forms.removeWhere((f) => f.id == formId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> toggleFormActive(String formId) async {
    final form = getFormById(formId);
    if (form == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiClient.put('/forms/$formId', body: {
        'is_active': !form.isActive,
      });
      final index = _forms.indexWhere((f) => f.id == formId);
      if (index >= 0) {
        _forms[index] = copyFormModel(form, isActive: !form.isActive);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<List<int>> exportResponses(String formId,
      {String format = 'xlsx'}) async {
    try {
      final bytes = await ApiClient.getBytes(
        '/forms/$formId/export',
        query: {'format': format},
      );
      return bytes;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }
    notifyListeners();
    return <int>[];
  }

  Future<bool> createForm(FormModel form) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.post('/forms', body: form.toCreateJson());
      final created =
          data is Map ? FormModel.fromJson({...data}) : form;
      _forms.add(created);
      try {
        await ApiClient.put(
          '/forms/${created.id}/settings',
          body: form.toSettingsJson(),
        );
      } catch (_) {}
      for (var i = 0; i < form.questions.length; i++) {
        try {
          await ApiClient.post(
            '/forms/${created.id}/questions',
            body: form.questions[i].toQuestionJson(orderIndex: i + 1),
          );
        } catch (_) {}
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateForm(FormModel form) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data =
          await ApiClient.put('/forms/${form.id}', body: form.toUpdateJson());
      try {
        await ApiClient.put(
          '/forms/${form.id}/settings',
          body: form.toSettingsJson(),
        );
      } catch (_) {}
      for (var i = 0; i < form.questions.length; i++) {
        try {
          final q = form.questions[i];
          if (q.id.startsWith('q') && q.id.length > 10) {
            await ApiClient.post(
              '/forms/${form.id}/questions',
              body: q.toQuestionJson(orderIndex: i + 1),
            );
          } else {
            await ApiClient.put(
              '/questions/${q.id}',
              body: q.toQuestionJson(orderIndex: i + 1),
            );
          }
        } catch (_) {}
      }
      final updated =
          data is Map ? FormModel.fromJson({...data}) : form;
      final index = _forms.indexWhere((f) => f.id == form.id);
      if (index >= 0) {
        _forms[index] = updated;
      } else {
        _forms.add(updated);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
