import 'package:flutter/material.dart';

class StatsNotifier extends ChangeNotifier {
  Map<String, int>? _userStats;
  String? _currentUserId;
  bool _isLoading = false;
  String? _error;

  Map<String, int>? get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateStats(String userId, Map<String, int> stats) {
    _currentUserId = userId;
    _userStats = stats;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void notifyStatsChanged() {
    notifyListeners();
  }

  void clearStats() {
    _currentUserId = null;
    _userStats = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

final statsNotifier = StatsNotifier();