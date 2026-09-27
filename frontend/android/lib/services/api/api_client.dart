import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:hi_docs/services/api/api_error_messages.dart';
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

  /// Callback yang dipanggil SEKALI saat server membalas 401 (access token
  /// kedaluwarsa). AuthProvider mengisinya dengan `refreshSession()` sehingga
  /// token diperpanjang otomatis dan pengguna tidak perlu login ulang selama
  /// refresh token (14 hari) masih berlaku.
  static Future<bool> Function()? onUnauthorized;

  /// Single-flight: beberapa request yang kena 401 bersamaan hanya memicu SATU
  /// panggilan /auth/refresh. Ini penting karena refresh token di backend
  /// bersifat sekali pakai (dirotasi) — kalau dipanggil dua kali bersamaan,
  /// panggilan kedua akan ditolak dan sesi bisa dicabut semua.
  static Future<bool>? _refreshInFlight;

  /// Endpoint auth yang TIDAK boleh memicu auto-refresh.
  ///
  /// Yang paling penting: `/auth/refresh` sendiri. Kalau request refresh dibalas
  /// 401 lalu helper ini mencoba refresh lagi, ia akan menunggu future dirinya
  /// sendiri (_refreshInFlight) yang belum pernah selesai -> DEADLOCK (aplikasi
  /// menggantung). Endpoint login/OTP juga tidak perlu refresh.
  static bool _isAuthEndpoint(http.Response response) {
    final path = response.request?.url.path ?? '';
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/verify-otp') ||
        path.contains('/auth/resend-otp') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password') ||
        path.contains('/auth/refresh');
  }

  static Future<bool> _ensureRefreshed() {
    final refresher = onUnauthorized;
    if (refresher == null) return Future.value(false);
    return _refreshInFlight ??= refresher().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  /// Jalankan request; bila balasannya 401 dan refresh token masih hidup,
  /// perbarui token lalu ulangi request satu kali dengan access token baru.
  static Future<http.Response> _sendWithAuthRetry(
    Future<http.Response> Function() send,
  ) async {
    var response = await send();
    if (response.statusCode != 401 ||
        onUnauthorized == null ||
        _isAuthEndpoint(response)) {
      return response;
    }

    final refreshed = await _ensureRefreshed();
    if (!refreshed) return response;

    // _headers() membaca ApiClient.token yang sudah diperbarui refreshSession().
    return send();
  }

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

    // `errors` berisi SEBAB sebenarnya dari kegagalan validasi backend
    // (mis. field 'RespondentEmail' gagal 'required'). Dulu field ini dibuang
    // sehingga pengguna hanya melihat "Invalid request payload" tanpa tahu
    // apa yang harus diperbaiki.
    Object? detail;

    if (decoded is Map) {
      if (decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded['error'] != null) {
        message = decoded['error'].toString();
      }
      detail = decoded['errors'] ?? decoded['error'];
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }

    throw ApiException(
      describeApiError(message, detail, statusCode: response.statusCode),
      statusCode: response.statusCode,
    );
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  static Future<dynamic> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _sendWithAuthRetry(
      () => http.get(_uri(path, query), headers: _headers()).timeout(
            _timeout,
            onTimeout: () => throw ApiException(
              'Koneksi timeout. Periksa jaringan Anda.',
            ),
          ),
    );
    return _parse(response);
  }

  static Future<dynamic> post(
    String path, {
    Object? body,
    bool json = true,
  }) async {
    final payload = json ? jsonEncode(body ?? {}) : body;
    final response = await _sendWithAuthRetry(
      () => http
          .post(_uri(path), headers: _headers(), body: payload)
          .timeout(
            _timeout,
            onTimeout: () => throw ApiException(
              'Koneksi timeout. Periksa jaringan Anda.',
            ),
          ),
    );
    return _parse(response);
  }

  static Future<dynamic> put(String path, {Object? body}) async {
    final payload = jsonEncode(body ?? {});
    final response = await _sendWithAuthRetry(
      () => http
          .put(_uri(path), headers: _headers(), body: payload)
          .timeout(
            _timeout,
            onTimeout: () => throw ApiException(
              'Koneksi timeout. Periksa jaringan Anda.',
            ),
          ),
    );
    return _parse(response);
  }

  static Future<dynamic> delete(String path) async {
    final response = await _sendWithAuthRetry(
      () => http.delete(_uri(path), headers: _headers()).timeout(
            _timeout,
            onTimeout: () => throw ApiException(
              'Koneksi timeout. Periksa jaringan Anda.',
            ),
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
    Object? detail;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
        detail = decoded['errors'] ?? decoded['error'];
      }
    } catch (_) {}
    throw ApiException(
      describeApiError(message, detail, statusCode: response.statusCode),
      statusCode: response.statusCode,
    );
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

  // ---------------------------------------------------------------
  // Grade / Skor
  // ---------------------------------------------------------------

  /// Simpan grade/score untuk satu response.
  /// endpoint: POST /forms/{formId}/responses/{responseId}/grade
  static Future<void> saveResponseGrade({
    required String formId,
    required String responseId,
    required double totalScore,
    Map<String, double>? essayScores,
  }) async {
    await post(
      '/forms/$formId/responses/$responseId/grade',
      body: {
        'total_score': totalScore,
        if (essayScores != null) 'essay_scores': essayScores,
      },
    );
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

  // ---------------------------------------------------------------
  // Pengawasan ujian: pencabutan akses
  // ---------------------------------------------------------------

  /// Kabarkan ke backend bahwa siswa telah melanggar batas keluar.
  /// Backend seharusnya menandai `access_revoked = true` pada sesi ini.
  /// Bila endpoint belum ada di backend, method ini diam-diam gagal
  /// (return false) tanpa crash.
  static Future<bool> revokeExamAccess(String responseId) async {
    try {
      await post(
        '/public/responses/$responseId/revoke-access',
        body: {'reason': 'EXIT_LIMIT_EXCEEDED'},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cek ke backend apakah akses ujian untuk email+form tertentu sudah
  /// dicabut (karena pelanggaran keluar berulang). Return `true` bila
  /// diizinkan; `false` bila dicabut. Graceful: bila endpoint belum ada,
  /// anggap diizinkan agar user tidak terkunci.
  static Future<bool> checkExamAccess(
    String formSlug,
    String respondentEmail,
  ) async {
    try {
      final data = await get(
        '/public/forms/${Uri.encodeComponent(formSlug)}/check-access?email=${Uri.encodeComponent(respondentEmail)}',
      );
      if (data is Map) return data['allowed'] != false;
      return true;
    } catch (_) {
      return true;
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
