import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dhikr.dart';
import '../services/adhkar_service.dart';

class AdhkarProvider extends ChangeNotifier {
  static const _quickModeKey = 'quick_mode_enabled';

  List<Dhikr> _fullList = [];
  List<Dhikr> _adhkarList = [];
  int _currentIndex = 0;
  int _remainingCount = 0;
  bool _isLoading = false;
  bool _isCompleted = false;
  bool _isTransitioning = false;
  bool _quickMode = false;
  String _currentCategory = '';

  // ── Undo state ────────────────────────────────────
  int? _prevIndex;
  int? _prevRemainingCount;
  bool _canUndo = false;

  List<Dhikr> get adhkarList => _adhkarList;
  int get currentIndex => _currentIndex;
  int get remainingCount => _remainingCount;
  bool get isLoading => _isLoading;
  bool get isCompleted => _isCompleted;
  bool get isTransitioning => _isTransitioning;
  bool get quickMode => _quickMode;
  String get currentCategory => _currentCategory;
  bool get canUndo => _canUndo && !_isTransitioning;
  Dhikr? get currentDhikr =>
      _adhkarList.isNotEmpty && _currentIndex < _adhkarList.length
      ? _adhkarList[_currentIndex]
      : null;
  int get totalCount => _adhkarList.length;

  AdhkarProvider() {
    _loadQuickModePref();
  }

  Future<void> _loadQuickModePref() async {
    final prefs = await SharedPreferences.getInstance();
    _quickMode = prefs.getBool(_quickModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setQuickMode(bool value) async {
    _quickMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickModeKey, value);
  }

  Future<void> loadAdhkar(String category) async {
    _isLoading = true;
    _isCompleted = false;
    _isTransitioning = false;
    _canUndo = false;
    _currentCategory = category;
    notifyListeners();

    _fullList = await AdhkarService.loadAdhkar(category);
    _applyFilter();
    _currentIndex = 0;
    _remainingCount = _adhkarList.isNotEmpty ? _adhkarList[0].count : 0;
    _isLoading = false;
    notifyListeners();
  }

  void _applyFilter() {
    if (_quickMode) {
      _adhkarList = _fullList.where((d) => d.isPriority).toList();
    } else {
      _adhkarList = List.from(_fullList);
    }
  }

  /// Returns true if the tap was accepted (counter decremented).
  bool decrementCounter() {
    if (_isCompleted || _isTransitioning) return false;

    // Save state for undo
    _prevIndex = _currentIndex;
    _prevRemainingCount = _remainingCount;
    _canUndo = true;

    if (_remainingCount > 1) {
      _remainingCount--;
      notifyListeners();
      return true;
    } else if (_remainingCount == 1) {
      // Last tap for this dhikr — lock transitions
      _remainingCount = 0;
      _isTransitioning = true;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 400), () {
        _moveToNext();
        _isTransitioning = false;
        notifyListeners();
      });
      return true;
    }
    // _remainingCount is already 0, ignore
    return false;
  }

  /// Reverts the last decrement action (one level of undo).
  void undo() {
    if (!_canUndo || _isTransitioning) return;

    if (_prevIndex != null && _prevRemainingCount != null) {
      _currentIndex = _prevIndex!;
      _remainingCount = _prevRemainingCount!;
      _isCompleted = false;
      _canUndo = false;
      notifyListeners();
    }
  }

  void _moveToNext() {
    if (_currentIndex < _adhkarList.length - 1) {
      _currentIndex++;
      _remainingCount = _adhkarList[_currentIndex].count;
    } else {
      _isCompleted = true;
    }
  }

  void reset() {
    _currentIndex = 0;
    _remainingCount = _adhkarList.isNotEmpty ? _adhkarList[0].count : 0;
    _isCompleted = false;
    _isTransitioning = false;
    _canUndo = false;
    notifyListeners();
  }
}
