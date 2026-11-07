import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _tapToConfirmKey = 'tap_to_confirm';
  static const _showPhoneticKey = 'show_phonetic';
  static const _showTranslationKey = 'show_translation';
  static const _hasCompletedOnboardingKey = 'has_completed_onboarding';

  bool _tapToConfirm = true;
  bool _showPhonetic = false;
  bool _showTranslation = false;
  bool _hasCompletedOnboarding = false;
  bool _isInitialized = false;

  bool get tapToConfirm => _tapToConfirm;
  bool get showPhonetic => _showPhonetic;
  bool get showTranslation => _showTranslation;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitialized => _isInitialized;

  SettingsProvider() {
    _loadFromPrefs();
  }

  void setTapToConfirm(bool value) {
    _tapToConfirm = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setShowPhonetic(bool value) {
    _showPhonetic = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setShowTranslation(bool value) {
    _showTranslation = value;
    _saveToPrefs();
    notifyListeners();
  }

  void completeOnboarding({required bool showPhonetic, required bool showTranslation}) {
    _showPhonetic = showPhonetic;
    _showTranslation = showTranslation;
    _hasCompletedOnboarding = true;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _tapToConfirm = prefs.getBool(_tapToConfirmKey) ?? true;
    _showPhonetic = prefs.getBool(_showPhoneticKey) ?? false;
    _showTranslation = prefs.getBool(_showTranslationKey) ?? false;
    _hasCompletedOnboarding = prefs.getBool(_hasCompletedOnboardingKey) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tapToConfirmKey, _tapToConfirm);
    await prefs.setBool(_showPhoneticKey, _showPhonetic);
    await prefs.setBool(_showTranslationKey, _showTranslation);
    await prefs.setBool(_hasCompletedOnboardingKey, _hasCompletedOnboarding);
  }
}
