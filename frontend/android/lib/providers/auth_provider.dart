import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_docs/models/user_model.dart';
import 'package:hi_docs/services/api/api_client.dart';

const _kAuthTokenKey = 'auth_token';
const _kRefreshTokenKey = 'refresh_token';
const _kAuthUserKey = 'auth_user';

class AuthProvider extends ChangeNotifier {
  static const _secure = FlutterSecureStorage();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  String _pendingEmail = '';
  bool _otpSent = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isSuperAdmin => _currentUser?.role == 'superadmin';

  /// Akun admin / superadmin TIDAK didukung oleh aplikasi Android
  /// (dashboard admin hanya tersedia di web) — layar [AdminBlockedScreen]
  /// memakai getter ini untuk menampilkan penjelasan, dan login/OTP akan
  /// ditolak sebelum layar utama sempat mem-blank-kan layar.
  bool get isAdminRole => isAdmin || isSuperAdmin;

  static const String adminBlockedMessage =
      'Akun admin/superadmin tidak dapat masuk lewat aplikasi Android. '
      'Silakan gunakan HiDocs versi web di hidocs.my.id.';
  String _activeMode = 'user';
  String get activeMode => _activeMode;
  bool get isCreatorMode => _activeMode == 'creator';
  bool get otpSent => _otpSent;
  String get pendingEmail => _pendingEmail;

  AuthProvider() {
    _restoreSession();
    _loadMode();
  }

  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('active_mode');
      if (mode == 'creator' || mode == 'user') {
        _activeMode = mode!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setActiveMode(String mode) async {
    _activeMode = mode == 'creator' ? 'creator' : 'user';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_mode', _activeMode);
    } catch (_) {}
  }

  Future<void> toggleMode() async {
    await setActiveMode(isCreatorMode ? 'user' : 'creator');
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _secure.read(key: _kAuthTokenKey);
      var userJson = await _secure.read(key: _kAuthUserKey);
      if (userJson == null) {
        final prefs = await SharedPreferences.getInstance();
        final legacy = prefs.getString('auth_user');
        if (legacy != null) {
          userJson = legacy;
          await _secure.write(key: _kAuthUserKey, value: legacy);
          await prefs.remove('auth_user');
        }
      }

      if (token != null && token.isNotEmpty && userJson != null) {
        ApiClient.token = token;
        _currentUser = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = (data['token'] ?? '').toString();
    final refresh = (data['refresh_token'] ?? '').toString();
    final userJson = data['user'] ?? {};

    ApiClient.token = token;
    _currentUser = UserModel.fromJson(
      userJson is Map ? Map<String, dynamic>.from(userJson) : {},
    );

    await _secure.write(key: _kAuthTokenKey, value: token);
    if (refresh.isNotEmpty) {
      await _secure.write(key: _kRefreshTokenKey, value: refresh);
    }
    await _secure.write(key: _kAuthUserKey, value: jsonEncode(userJson));
  }

  Future<bool> refreshSession() async {
    try {
      final refresh = await _secure.read(key: _kRefreshTokenKey);
      if (refresh == null || refresh.isEmpty) return false;
      final data = await ApiClient.post(
        '/auth/refresh',
        body: {'refresh_token': refresh},
      );
      if (data is Map) {
        await _persistSession(Map<String, dynamic>.from(data));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.post(
        '/auth/login',
        body: {
          'email': username.trim(),
          'password': password,
        },
      );

      if (data is Map) {
        await _persistSession(Map<String, dynamic>.from(data));
      }

      // Tolak admin/superadmin: kalau dibiarkan, RoleGate langsung memuat
      // dashboard admin sehingga layar menjadi blank putih.
      if (isAdminRole) {
        await _clearLocalSession();
        _error = adminBlockedMessage;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(
    String email,
    String username,
    String password,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiClient.post(
        '/auth/register',
        body: {
          'name': username.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      _pendingEmail = email.trim();
      _otpSent = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void backToRegister() {
    _otpSent = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> verifyOtp(String otpCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.post(
        '/auth/verify-otp',
        body: {
          'email': _pendingEmail,
          'otp_code': otpCode.trim(),
        },
      );

      if (data is Map) {
        await _persistSession(Map<String, dynamic>.from(data));
      }

      _otpSent = false;
      _pendingEmail = '';

      if (isAdminRole) {
        await _clearLocalSession();
        _error = adminBlockedMessage;
        _isLoading = false;
        notifyListeners();
        return false;
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

  Future<bool> resendOtp() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiClient.post(
        '/auth/resend-otp',
        body: {
          'email': _pendingEmail,
        },
      );

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

  Future<void> updateProfile({
    required String name,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiClient.put(
        '/users/me',
        body: {
          'name': name.trim(),
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      );

      if (data is Map) {
        _currentUser = UserModel.fromJson(
          Map<String, dynamic>.from(data),
        );

        await _secure.write(key: _kAuthUserKey, value: jsonEncode(data));
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Koneksi gagal. Periksa jaringan atau server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Hapus sesi dari memori + secure storage TANPA memanggil API logout
  /// (dipakai saat admin diblokir, ketika sesi baru saja dibuat/dipulihkan).
  Future<void> _clearLocalSession() async {
    _currentUser = null;
    ApiClient.token = null;
    ApiClient.examSessionToken = null;
    _otpSent = false;
    _pendingEmail = '';
    _activeMode = 'user';

    try {
      await _secure.delete(key: _kAuthTokenKey);
      await _secure.delete(key: _kRefreshTokenKey);
      await _secure.delete(key: _kAuthUserKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user');
      await prefs.setString('active_mode', 'user');
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout');
    } catch (_) {}
    await _clearLocalSession();

    notifyListeners();
  }

  void clearError() {
    _error = null;
  }
}
