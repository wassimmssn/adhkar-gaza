import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _tapToConfirmKey = 'tap_to_confirm';

  bool _tapToConfirm = true;

  bool get tapToConfirm => _tapToConfirm;

  SettingsProvider() {
    _loadFromPrefs();
  }

  void setTapToConfirm(bool value) {
    _tapToConfirm = value;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _tapToConfirm = prefs.getBool(_tapToConfirmKey) ?? true;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tapToConfirmKey, _tapToConfirm);
  }
}
