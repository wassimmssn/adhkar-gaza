import 'package:flutter/material.dart';
import '../models/daily_tracker.dart';
import '../services/streak_service.dart';

class StreakProvider extends ChangeNotifier {
  Map<String, DayCompletion> _data = {};
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalSessions = 0;
  bool _isLoading = true;

  Map<String, DayCompletion> get data => _data;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get totalSessions => _totalSessions;
  bool get isLoading => _isLoading;

  DayCompletion get todayData {
    final todayKey = StreakService.formatDateKey(DateTime.now());
    return _data[todayKey] ?? DayCompletion(dateKey: todayKey);
  }

  StreakProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _data = await StreakService.loadAllData();
    final savedBest = await StreakService.getSavedBestStreak();
    _currentStreak = StreakService.calculateCurrentStreak(_data, DateTime.now());
    _bestStreak = StreakService.calculateBestStreak(_data, savedBest);
    _totalSessions = StreakService.calculateTotalCompletedSessions(_data);

    if (_currentStreak > _bestStreak) {
      _bestStreak = _currentStreak;
      await StreakService.saveBestStreak(_bestStreak);
    }

    _isLoading = false;
    notifyListeners();
  }

  DayCompletion? getDataForDate(DateTime date) {
    final key = StreakService.formatDateKey(date);
    return _data[key];
  }

  /// Records a completed session for a specific category
  Future<void> recordCompletion(String category, {int dhikrsCount = 0}) async {
    final now = DateTime.now();
    final todayKey = StreakService.formatDateKey(now);

    final day = _data[todayKey] ?? DayCompletion(dateKey: todayKey);

    if (category == 'morning') {
      day.morning = true;
    } else if (category == 'evening') {
      day.evening = true;
    } else if (category.startsWith('after_')) {
      final prayerId = category.replaceFirst('after_', '');
      if (!day.prayers.contains(prayerId)) {
        day.prayers.add(prayerId);
      }
    }

    if (dhikrsCount > 0) {
      day.totalDhikrCount += dhikrsCount;
    }

    _data[todayKey] = day;

    // Recalculate stats
    _currentStreak = StreakService.calculateCurrentStreak(_data, now);
    _bestStreak = StreakService.calculateBestStreak(_data, _bestStreak);
    if (_currentStreak > _bestStreak) {
      _bestStreak = _currentStreak;
      await StreakService.saveBestStreak(_bestStreak);
    }
    _totalSessions = StreakService.calculateTotalCompletedSessions(_data);

    notifyListeners();
    await StreakService.saveAllData(_data);
  }
}
