import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _tapToConfirmKey = 'tap_to_confirm';
  static const _showPhoneticKey = 'show_phonetic';
  static const _showAudioKey = 'show_audio';
  static const _appLanguageKey = 'app_language';
  static const _hasCompletedOnboardingKey = 'has_completed_onboarding';

  bool _tapToConfirm = true;
  bool _showPhonetic = false;
  bool _showAudio = true;
  String _language = 'ar';
  bool _hasCompletedOnboarding = false;
  bool _isInitialized = false;

  bool get tapToConfirm => _tapToConfirm;
  bool get showPhonetic => _showPhonetic;
  bool get showAudio => _showAudio;
  String get language => _language;
  bool get isFrench => _language == 'fr';
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

  void setShowAudio(bool value) {
    _showAudio = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setLanguage(String value) {
    if (_language != value) {
      _language = value;
      // If switching to French, default phonetic to true for accessibility
      if (value == 'fr') {
        _showPhonetic = true;
      }
      _saveToPrefs();
      notifyListeners();
    }
  }

  void completeOnboarding({
    required String language,
    required bool showPhonetic,
    required bool showAudio,
  }) {
    _language = language;
    _showPhonetic = showPhonetic;
    _showAudio = showAudio;
    _hasCompletedOnboarding = true;
    _saveToPrefs();
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        _tapToConfirmKey: _tapToConfirm,
        _showPhoneticKey: _showPhonetic,
        _showAudioKey: _showAudio,
        _appLanguageKey: _language,
        _hasCompletedOnboardingKey: _hasCompletedOnboarding,
      };

  void loadFromJson(Map<String, dynamic> json) {
    if (json.containsKey(_tapToConfirmKey)) {
      _tapToConfirm = json[_tapToConfirmKey] as bool? ?? true;
    }
    if (json.containsKey(_showPhoneticKey)) {
      _showPhonetic = json[_showPhoneticKey] as bool? ?? false;
    }
    if (json.containsKey(_showAudioKey)) {
      _showAudio = json[_showAudioKey] as bool? ?? true;
    }
    if (json.containsKey(_appLanguageKey)) {
      _language = json[_appLanguageKey] as String? ?? 'ar';
    }
    if (json.containsKey(_hasCompletedOnboardingKey)) {
      _hasCompletedOnboarding = json[_hasCompletedOnboardingKey] as bool? ?? false;
    }
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _tapToConfirm = prefs.getBool(_tapToConfirmKey) ?? true;
    _showPhonetic = prefs.getBool(_showPhoneticKey) ?? false;
    _showAudio = prefs.getBool(_showAudioKey) ?? true;
    _language = prefs.getString(_appLanguageKey) ?? 'ar';
    _hasCompletedOnboarding = prefs.getBool(_hasCompletedOnboardingKey) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tapToConfirmKey, _tapToConfirm);
    await prefs.setBool(_showPhoneticKey, _showPhonetic);
    await prefs.setBool(_showAudioKey, _showAudio);
    await prefs.setString(_appLanguageKey, _language);
    await prefs.setBool(_hasCompletedOnboardingKey, _hasCompletedOnboarding);
  }
}
