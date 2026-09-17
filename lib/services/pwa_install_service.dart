@JS()
library;

import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:shared_preferences/shared_preferences.dart';

/// Extension type for the non-standard BeforeInstallPromptEvent
extension type _BeforeInstallPromptEvent._(JSObject _) implements web.Event {
  external JSPromise prompt();
}

/// Lightweight service for PWA installation.
///
/// - Listens for `beforeinstallprompt` and saves the event.
/// - Exposes [canInstall] and [isIos] for UI decisions.
/// - [promptInstall] triggers the native install prompt (Chrome/Edge/Android).
class PwaInstallService extends ChangeNotifier {
  static const _dismissKey = 'install_prompt_dismissed';

  _BeforeInstallPromptEvent? _deferredPrompt;
  bool _isIos = false;
  bool _isStandalone = false;
  bool _isDismissed = false;

  bool get isIos => _isIos;
  bool get isStandalone => _isStandalone;
  bool get isDismissed => _isDismissed;
  bool get canNativeInstall => _deferredPrompt != null;

  /// True if the app is NOT in standalone mode AND the user hasn't explicitly dismissed it
  bool get shouldShowPrompt => !_isStandalone && !_isDismissed;

  PwaInstallService() {
    // Register event listeners SYNCHRONOUSLY so we never miss
    // the beforeinstallprompt event (fires very early in page load)
    web.window.addEventListener(
      'beforeinstallprompt',
      _onBeforeInstallPrompt.toJS,
    );
    web.window.addEventListener('appinstalled', _onAppInstalled.toJS);

    _init();
  }

  Future<void> _init() async {
    // 1. Detect iOS
    final ua = web.window.navigator.userAgent.toLowerCase();
    _isIos =
        ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');

    // 2. Track 'standalone' display mode
    final mediaQuery = web.window.matchMedia('(display-mode: standalone)');
    _isStandalone = mediaQuery.matches;

    // Listen to display-mode changes
    mediaQuery.addEventListener(
      'change',
      ((web.Event e) {
        final mqe = e as web.MediaQueryListEvent;
        _isStandalone = mqe.matches;
        notifyListeners();
      }).toJS,
    );

    // 3. Load dismissed state
    final prefs = await SharedPreferences.getInstance();
    _isDismissed = prefs.getBool(_dismissKey) ?? false;
    notifyListeners();
  }

  void _onBeforeInstallPrompt(web.Event event) {
    try {
      event.preventDefault();
    } catch (_) {}
    _deferredPrompt = event as _BeforeInstallPromptEvent;
    // We don't strictly base UI purely on _deferredPrompt anymore
    // but we keep it to trigger the prompt later.
    notifyListeners();
  }

  void _onAppInstalled(web.Event event) {
    _isStandalone = true;
    _deferredPrompt = null;
    notifyListeners();
  }

  /// Triggers the native install prompt (Chrome/Android only).
  /// Returns [true] if the prompt was shown, [false] if not available.
  Future<bool> promptInstall() async {
    if (_deferredPrompt != null) {
      try {
        await _deferredPrompt!.prompt().toDart;
        _deferredPrompt = null;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('PWA Install Prompt Error: $e');
        return false;
      }
    }
    return false;
  }

  /// Permanently dismisses the install prompt for this session/cache
  Future<void> dismissPrompt() async {
    _isDismissed = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissKey, true);
  }
}
