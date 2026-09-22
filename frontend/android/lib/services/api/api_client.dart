import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hi_docs/utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static String get baseUrl => AppConstants.appBaseUrl;

  static const Duration _timeout = Duration(seconds: 30);

  static String? token;

  static String? examSessionToken;

  static Map<String, String> _headers({bool json = true, String? sessionToken}) {
    final headers = <String, String>{'Accept': 'application/json'};

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final st = sessionToken ?? examSessionToken;
    if (st != null && st.isNotEmpty) {
      headers['X-Session-Token'] = st;
    }

    return headers;
  }

  static Future<dynamic> _parse(http.Response response) async {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    var message = 'Terjadi kesalahan (${response.statusCode})';

    if (decoded is Map) {
      if (decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  static Future<dynamic> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response =
        await http.get(_uri(path, query), headers: _headers()).timeout(
      _timeout,
      onTimeout: () => throw ApiException(
        'Koneksi timeout. Periksa jaringan Anda.',
      ),
    );
    return _parse(response);
  }

  static Future<dynamic> post(
    String path, {
    Object? body,
    bool json = true,
  }) async {
    final response = await http
        .post(
          _uri(path),
          headers: _headers(),
          body: json ? jsonEncode(body ?? {}) : body,
        )
        .timeout(
      _timeout,
      onTimeout: () => throw ApiException(
        'Koneksi timeout. Periksa jaringan Anda.',
      ),
    );
    return _parse(response);
  }

  static Future<dynamic> put(String path, {Object? body}) async {
    final response = await http
        .put(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(body ?? {}),
        )
        .timeout(
      _timeout,
      onTimeout: () => throw ApiException(
        'Koneksi timeout. Periksa jaringan Anda.',
      ),
    );
    return _parse(response);
  }

  static Future<dynamic> delete(String path) async {
    final response = await http
        .delete(_uri(path), headers: _headers())
        .timeout(
      _timeout,
      onTimeout: () => throw ApiException(
        'Koneksi timeout. Periksa jaringan Anda.',
      ),
    );
    return _parse(response);
  }

  static Future<List<int>> getBytes(
    String path, {
    Map<String, String>? query,
  }) async {
    final response =
        await http.get(_uri(path, query), headers: _headers()).timeout(
      _timeout,
      onTimeout: () => throw ApiException(
        'Koneksi timeout. Periksa jaringan Anda.',
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes.toList();
    }
    var message = 'Terjadi kesalahan (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {}
    throw ApiException(message, statusCode: response.statusCode);
  }

  static Future<dynamic> uploadFile(
    String path, {
    String? filePath,
    List<int>? fileBytes,
    String fileName = 'upload',
    String field = 'file',
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers(json: false));
    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(field, filePath,
          filename: fileName));
    } else if (fileBytes != null) {
      request.files.add(
          http.MultipartFile.fromBytes(field, fileBytes, filename: fileName));
    } else {
      throw ApiException('File tidak ditemukan.');
    }
    final streamed = await request.send().timeout(
      _timeout,
      onTimeout: () => throw ApiException(
        'Koneksi timeout. Periksa jaringan Anda.',
      ),
    );
    final response = await http.Response.fromStream(streamed);
    return _parse(response);
  }

  static Future<dynamic> getAdminDashboardStats() =>
      get('/admin/dashboard/stats');

  static Future<dynamic> getAdminCreators() => get('/admin/creators');

  static Future<dynamic> createCreator(Map<String, dynamic> body) =>
      post('/admin/creators', body: body);

  static Future<dynamic> updateCreatorStatus(String id, bool active) =>
      put('/admin/creators/$id/status', body: {'is_active': active});

  static Future<dynamic> getAdminForms() => get('/admin/forms');

  static Future<dynamic> deleteAdminForm(String id) =>
      delete('/admin/forms/$id');

  static Future<dynamic> getSuperadminAdmins() =>
      get('/superadmin/list-admin');

  static Future<dynamic> createSuperadminAdmin(Map<String, dynamic> body) =>
      post('/superadmin/create-admin', body: body);

  static Future<dynamic> getRealtimeMetrics() =>
      get('/admin/metrics/realtime');

  static Future<dynamic> getSystemMetrics() => get('/admin/metrics/system');

  static Future<dynamic> getLiveExamsMetrics() =>
      get('/admin/metrics/live-exams');

  static Future<dynamic> getTrafficHistoryMetrics() =>
      get('/admin/metrics/traffic-history');

  static Future<dynamic> getFormMetrics(String id) =>
      get('/admin/metrics/forms/$id');

  // ---------------------------------------------------------------
  // Endpoint pengawasan ujian (public)
  // ---------------------------------------------------------------

  /// Kirim satu event pelanggaran/pengawasan selama ujian.
  static Future<bool> sendTelemetry({
    required String responseId,
    required String eventType,
    String? eventMessage,
    int currentQuestionIndex = 0,
    String? metadata,
  }) async {
    try {
      await post(
        '/public/responses/$responseId/telemetry',
        body: {
          'event_type': eventType,
          if (eventMessage != null) 'event_message': eventMessage,
          'current_question_index': currentQuestionIndex,
          if (metadata != null) 'metadata': metadata,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Simpan satu jawaban secara bertahap (autosave).
  static Future<bool> autosaveAnswer({
    required String responseId,
    required String questionId,
    String? selectedOptionId,
    String answerText = '',
    bool isFlagged = false,
    List<Map<String, dynamic>>? matchPairs,
  }) async {
    try {
      await post(
        '/public/responses/$responseId/autosave',
        body: {
          'question_id': questionId,
          if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
          'answer_text': answerText,
          'is_flagged': isFlagged,
          if (matchPairs != null && matchPairs.isNotEmpty)
            'match_pairs': matchPairs,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ambil status sesi ujian (untuk resume setelah aplikasi ditutup).
  static Future<Map<String, dynamic>?> getExamSession(String responseId) async {
    try {
      final data = await get('/public/responses/$responseId/session');
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Konfirmasi siswa sudah membaca peringatan, sesi dilanjutkan.
  static Future<bool> acknowledgeWarning(String responseId) async {
    try {
      await post('/public/responses/$responseId/acknowledge-warning');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> uploadQuestionImage(
      Uint8List bytes, String fileName) async {
    final request =
        http.MultipartRequest('POST', _uri('/questions/upload-image'));
    request.headers.addAll(_headers(json: false));
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: fileName),
    );
    final streamed = await request.send().timeout(
      _timeout,
      onTimeout: () => throw ApiException(
        'Koneksi timeout. Periksa jaringan Anda.',
      ),
    );
    final response = await http.Response.fromStream(streamed);
    final parsed = await _parse(response);
    if (parsed is Map && parsed['img_url'] != null) {
      return parsed['img_url'].toString();
    }
    if (parsed is String) return parsed;
    return null;
  }
}
