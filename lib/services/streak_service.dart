import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_tracker.dart';

class StreakService {
  static const String _storageKey = 'streak_tracker_data_v1';
  static const String _bestStreakKey = 'streak_tracker_best_streak_v1';

  static String formatDateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    return DateTime.now();
  }

  static Future<Map<String, DayCompletion>> loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    try {
      final Map<String, dynamic> rawMap = json.decode(jsonString);
      final Map<String, DayCompletion> result = {};
      rawMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key] = DayCompletion.fromJson(value);
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveAllData(Map<String, DayCompletion> data) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> rawMap = {};
    data.forEach((key, value) {
      rawMap[key] = value.toJson();
    });
    await prefs.setString(_storageKey, json.encode(rawMap));
  }

  static Future<int> getSavedBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestStreakKey) ?? 0;
  }

  static Future<void> saveBestStreak(int best) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestStreakKey, best);
  }

  /// Calculates current active streak count in days up to today.
  static int calculateCurrentStreak(
    Map<String, DayCompletion> data,
    DateTime now,
  ) {
    final todayKey = formatDateKey(now);
    final yesterdayKey = formatDateKey(now.subtract(const Duration(days: 1)));

    final today = data[todayKey];
    final yesterday = data[yesterdayKey];

    // If neither today nor yesterday has activity, streak is 0
    if ((today == null || !today.hasAnyActivity) &&
        (yesterday == null || !yesterday.hasAnyActivity)) {
      return 0;
    }

    int streak = 0;
    // Start counting back from today if today has activity, otherwise from yesterday
    DateTime currentCheck = (today != null && today.hasAnyActivity)
        ? now
        : now.subtract(const Duration(days: 1));

    while (true) {
      final key = formatDateKey(currentCheck);
      final entry = data[key];
      if (entry != null && entry.hasAnyActivity) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculates all-time best streak
  static int calculateBestStreak(
    Map<String, DayCompletion> data,
    int savedBest,
  ) {
    if (data.isEmpty) return savedBest;

    final sortedKeys = data.keys.toList()..sort();
    int currentRun = 0;
    int maxStreak = savedBest;

    DateTime? prevDate;

    for (final key in sortedKeys) {
      final entry = data[key];
      if (entry == null || !entry.hasAnyActivity) {
        currentRun = 0;
        prevDate = null;
        continue;
      }

      final date = parseDateKey(key);
      if (prevDate == null) {
        currentRun = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          currentRun = 1;
        }
      }

      prevDate = date;
      if (currentRun > maxStreak) {
        maxStreak = currentRun;
      }
    }

    return maxStreak;
  }

  /// Calculates total completed sessions across history
  static int calculateTotalCompletedSessions(Map<String, DayCompletion> data) {
    int total = 0;
    for (var entry in data.values) {
      total += entry.totalCompletedItems;
    }
    return total;
  }
}
