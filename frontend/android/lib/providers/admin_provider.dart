import 'package:flutter/foundation.dart';
import 'package:hi_docs/models/user_model.dart';
import 'package:hi_docs/services/api/api_client.dart';

class AdminProvider with ChangeNotifier {
  Map<String, dynamic>? _dashboardStats;
  List<UserModel> _creators = [];
  List<UserModel> _admins = [];
  List<Map<String, dynamic>> _allForms = [];

  bool _isLoadingStats = false;
  bool _isLoadingCreators = false;
  bool _isLoadingAdmins = false;
  bool _isLoadingForms = false;
  String? _errorMessage;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<UserModel> get creators => _creators;
  List<UserModel> get admins => _admins;
  List<Map<String, dynamic>> get allForms => _allForms;

  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingCreators => _isLoadingCreators;
  bool get isLoadingAdmins => _isLoadingAdmins;
  bool get isLoadingForms => _isLoadingForms;
  String? get errorMessage => _errorMessage;

  String _parseError(dynamic e) {
    final str = e.toString();
    if (str.contains('403') || str.toLowerCase().contains('forbidden')) {
      return 'Akses ditolak (403 Forbidden). Anda tidak memiliki wewenang administrator.';
    }
    if (str.contains('401') || str.toLowerCase().contains('unauthorized')) {
      return 'Sesi habis (401 Unauthorized). Silakan login kembali.';
    }
    return str.replaceFirst('ApiException: ', '');
  }

  Future<void> fetchDashboardStats() async {
    _isLoadingStats = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.getAdminDashboardStats();
      if (res is Map<String, dynamic>) {
        _dashboardStats = res;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> fetchCreators() async {
    _isLoadingCreators = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.getAdminCreators();
      if (res is List) {
        _creators = res.map((item) => UserModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingCreators = false;
      notifyListeners();
    }
  }

  Future<bool> createCreator(String name, String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.createCreator({
        'name': name,
        'email': email,
        'password': password,
      });
      if (res is Map<String, dynamic>) {
        _creators.insert(0, UserModel.fromJson(res));
        notifyListeners();
        return true;
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCreatorStatus(String creatorId, bool isActive) async {
    _errorMessage = null;
    try {
      await ApiClient.updateCreatorStatus(creatorId, isActive);
      final index = _creators.indexWhere((c) => c.id == creatorId);
      if (index != -1) {
        await fetchCreators();
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAllForms() async {
    _isLoadingForms = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.getAdminForms();
      if (res is List) {
        _allForms = res.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingForms = false;
      notifyListeners();
    }
  }

  Future<bool> deleteForm(String formId) async {
    _errorMessage = null;
    try {
      await ApiClient.deleteAdminForm(formId);
      _allForms.removeWhere((f) => f['id'].toString() == formId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAdmins() async {
    _isLoadingAdmins = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.getSuperadminAdmins();
      if (res is List) {
        _admins = res.map((item) => UserModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingAdmins = false;
      notifyListeners();
    }
  }

  Future<bool> createAdmin(String name, String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.createSuperadminAdmin({
        'name': name,
        'email': email,
        'password': password,
      });
      if (res is Map<String, dynamic>) {
        _admins.insert(0, UserModel.fromJson(res));
        notifyListeners();
        return true;
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }
}
