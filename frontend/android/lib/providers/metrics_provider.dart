import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hi_docs/models/metrics_model.dart';
import 'package:hi_docs/services/api/api_client.dart';

class MetricsProvider with ChangeNotifier {
  RealtimeMetricsModel? _realtime;
  SystemMetricsModel? _system;
  List<LiveExamMetricsModel> _liveExams = [];
  TrafficHistoryModel? _history;
  Map<String, dynamic>? _formMetrics;
  String? _formMetricsId;

  bool _isLoading = false;
  String? _errorMessage;

  Timer? _pollerTimer;
  int _pollIntervalSeconds = 5;
  bool _isPolling = false;

  RealtimeMetricsModel? get realtime => _realtime;
  SystemMetricsModel? get system => _system;
  List<LiveExamMetricsModel> get liveExams => _liveExams;
  TrafficHistoryModel? get history => _history;
  Map<String, dynamic>? get formMetrics => _formMetrics;
  String? get formMetricsId => _formMetricsId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pollIntervalSeconds => _pollIntervalSeconds;
  bool get isPolling => _isPolling;

  Future<void> fetchAllMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiClient.getRealtimeMetrics(),
        ApiClient.getSystemMetrics(),
        ApiClient.getLiveExamsMetrics(),
        ApiClient.getTrafficHistoryMetrics(),
      ]);

      if (results[0] is Map<String, dynamic>) {
        _realtime = RealtimeMetricsModel.fromJson(results[0]);
      }
      if (results[1] is Map<String, dynamic>) {
        _system = SystemMetricsModel.fromJson(results[1]);
      }
      if (results[2] is List) {
        _liveExams = (results[2] as List)
            .map((item) => LiveExamMetricsModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      if (results[3] is Map<String, dynamic>) {
        _history = TrafficHistoryModel.fromJson(results[3]);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchFormMetrics(String formId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiClient.getFormMetrics(formId);
      if (res is Map<String, dynamic>) {
        _formMetrics = res;
        _formMetricsId = formId;
        return res;
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startPolling({int seconds = 5}) {
    _pollIntervalSeconds = seconds;
    stopPolling();
    _isPolling = true;
    fetchAllMetrics();
    _pollerTimer = Timer.periodic(Duration(seconds: _pollIntervalSeconds), (_) {
      fetchAllMetrics();
    });
  }

  void stopPolling() {
    _pollerTimer?.cancel();
    _pollerTimer = null;
    _isPolling = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
