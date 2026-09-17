@JS()
library;

import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:shared_preferences/shared_preferences.dart';

// ── JS Interop Helpers ──────────────────────────────────────────────────────

@JS('requestNotificationPermission')
external JSPromise requestNotificationPermission();

@JS('getNotificationPermission')
external JSString getNotificationPermission();

@JS('subscribeToPush')
external JSPromise subscribeToPush(JSString preferencesJson);

@JS('unsubscribeFromPush')
external JSPromise unsubscribeFromPush();

@JS('sendTestPushViaWorker')
external JSPromise sendTestPushViaWorker();

@JS('getPushSubscriptionStatus')
external JSPromise getPushSubscriptionStatus();

@JS('showImmediateNotification')
external void showImmediateNotification(
  JSString title,
  JSString body,
  JSString category,
);

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Keys for SharedPreferences
  static const _morningEnabledKey = 'notif_morning_enabled';
  static const _morningOffsetKey = 'notif_morning_offset';
  static const _eveningEnabledKey = 'notif_evening_enabled';
  static const _eveningTypeKey = 'notif_evening_type';

  static const _latitudeKey = 'notif_latitude';
  static const _longitudeKey = 'notif_longitude';
  static const _cityKey = 'notif_city';
  static const _timezoneKey = 'notif_timezone';

  // State fields
  bool _morningEnabled = false;
  int _morningOffset = 15;
  bool _eveningEnabled = false;
  String _eveningType = 'asr_15';

  double _latitude = 31.5;
  double _longitude = 34.4667;
  String _city = 'غزة';
  String _timezone = 'Asia/Gaza';

  bool _permissionGranted = false;
  bool _isSubscribed = false;
  bool _isLoadingLocation = false;
  bool _isSyncing = false;

  // Getters
  String? lastSyncError;

  bool get morningEnabled => _morningEnabled;
  int get morningOffset => _morningOffset;
  bool get eveningEnabled => _eveningEnabled;
  String get eveningType => _eveningType;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get city => _city;
  String get timezone => _timezone;

  bool get hasPermission => _permissionGranted;
  bool get isSubscribed => _isSubscribed;
  bool get isSyncing => _isSyncing;
  bool get isLoadingLocation => _isLoadingLocation;

  Future<void> init() async {
    await _checkPermission();
    await _loadSettings();
    await _checkSubscriptionStatus();

    // Silently refresh IP location if we don't have stored coordinates
    if (_city == 'غزة' && _latitude == 31.5) {
      detectIpLocation();
    }

    // Auto-sync with Worker to ensure Cloudflare KV is up-to-date
    if (_isSubscribed && (_morningEnabled || _eveningEnabled)) {
      syncWithWorker();
    }
  }

  Future<void> _checkPermission() async {
    try {
      final status = getNotificationPermission().toDart;
      _permissionGranted = (status == 'granted');
    } catch (_) {
      _permissionGranted = false;
    }
    notifyListeners();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final result = await getPushSubscriptionStatus().toDart;
      final status = (result as JSString).toDart;
      _isSubscribed = (status == 'subscribed');
    } catch (_) {
      _isSubscribed = false;
    }
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    try {
      final promise = requestNotificationPermission();
      final result = await promise.toDart;
      final status = (result as JSString).toDart;
      _permissionGranted = (status == 'granted');
      notifyListeners();
      return _permissionGranted;
    } catch (e) {
      debugPrint('Notification Permission Request Error: $e');
      return false;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _morningEnabled = prefs.getBool(_morningEnabledKey) ?? false;
    _morningOffset = prefs.getInt(_morningOffsetKey) ?? 15;
    _eveningEnabled = prefs.getBool(_eveningEnabledKey) ?? false;
    _eveningType = prefs.getString(_eveningTypeKey) ?? 'asr_15';

    _latitude = prefs.getDouble(_latitudeKey) ?? 31.5;
    _longitude = prefs.getDouble(_longitudeKey) ?? 34.4667;
    _city = prefs.getString(_cityKey) ?? 'غزة';
    _timezone = prefs.getString(_timezoneKey) ?? 'Asia/Gaza';

    notifyListeners();
  }

  /// Build JSON preferences object for the Worker
  String _buildPreferencesJson() {
    return jsonEncode({
      'morningEnabled': _morningEnabled,
      'morningOffset': _morningOffset,
      'eveningEnabled': _eveningEnabled,
      'eveningType': _eveningType,
      'latitude': _latitude,
      'longitude': _longitude,
      'city': _city,
      'timezone': _timezone,
    });
  }

  /// Subscribe to Web Push and sync preferences with the Worker
  Future<void> syncWithWorker() async {
    if (!_permissionGranted) return;
    if (!_morningEnabled && !_eveningEnabled) {
      // If nothing is enabled, unsubscribe
      await _unsubscribeFromPush();
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final prefsJson = _buildPreferencesJson();
      final result = await subscribeToPush(prefsJson.toJS).toDart;
      final resultStr = (result as JSString).toDart;
      final decoded = jsonDecode(resultStr);
      _isSubscribed = decoded['success'] == true;
      if (!_isSubscribed) {
        lastSyncError = decoded['error']?.toString();
        debugPrint('Push subscribe failed: $lastSyncError');
      } else {
        lastSyncError = null;
      }
    } catch (e) {
      debugPrint('Push sync error: $e');
      _isSubscribed = false;
      lastSyncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _unsubscribeFromPush() async {
    try {
      await unsubscribeFromPush().toDart;
      _isSubscribed = false;
    } catch (e) {
      debugPrint('Unsubscribe error: $e');
    }
    notifyListeners();
  }

  // ── Settings Setters (each syncs with Worker) ─────────────────────────────

  Future<void> setMorningEnabled(bool enabled) async {
    _morningEnabled = enabled;
    notifyListeners();

    // Save to prefs in background to preserve user gesture context
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_morningEnabledKey, enabled);
    });

    await syncWithWorker();
  }

  Future<void> setMorningOffset(int offset) async {
    _morningOffset = offset;
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_morningOffsetKey, offset);
    });

    await syncWithWorker();
  }

  Future<void> setEveningEnabled(bool enabled) async {
    _eveningEnabled = enabled;
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_eveningEnabledKey, enabled);
    });

    await syncWithWorker();
  }

  Future<void> setEveningType(String type) async {
    _eveningType = type;
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_eveningTypeKey, type);
    });

    await syncWithWorker();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> detectIpLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      final resp = await web.window.fetch('https://ipwho.is/'.toJS).toDart;
      if (resp.ok) {
        final bodyText = await resp.text().toDart;
        final data = jsonDecode(bodyText.toDart);
        if (data is Map) {
          _city = data['city'] ?? _city;
          _latitude = (data['latitude'] as num?)?.toDouble() ?? _latitude;
          _longitude = (data['longitude'] as num?)?.toDouble() ?? _longitude;
          _timezone =
              (data['timezone'] is Map
                  ? data['timezone']['id']
                  : data['timezone']) ??
              _timezone;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cityKey, _city);
          await prefs.setDouble(_latitudeKey, _latitude);
          await prefs.setDouble(_longitudeKey, _longitude);
          await prefs.setString(_timezoneKey, _timezone);
        }
      }
    } catch (e) {
      debugPrint('Location IP fetch failed: $e. Using Gaza defaults.');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
      // Re-sync with Worker if subscribed (location changed)
      if (_isSubscribed) {
        await syncWithWorker();
      }
    }
  }

  // ── Test Notification ─────────────────────────────────────────────────────

  String? lastTestError;

  Future<bool> sendTestNotification() async {
    lastTestError = null;
    if (!_permissionGranted) {
      lastTestError = 'Permission not granted';
      return false;
    }

    // If subscribed to push, test via the Worker (real Web Push round-trip)
    if (_isSubscribed) {
      try {
        final result = await sendTestPushViaWorker().toDart;
        final resultStr = (result as JSString).toDart;
        debugPrint('Test push result: $resultStr');
        final decoded = jsonDecode(resultStr);
        if (decoded['success'] == true) {
          return true;
        }
        lastTestError = decoded['error']?.toString() ?? 'Unknown push error';
        debugPrint('Test push failed: $lastTestError');
        // Fall through to try local notification
      } catch (e) {
        lastTestError = e.toString();
        debugPrint('Test push via worker failed: $e');
        // Fall through to try local notification
      }
    }

    // Fallback: show local notification directly
    try {
      showImmediateNotification(
        'تنبيه تجريبي 🕌'.toJS,
        'هذا تنبيه تجريبي من تطبيق أذكار غزة للتأكد من عمل التنبيهات.'.toJS,
        'test'.toJS,
      );
      return true;
    } catch (e) {
      debugPrint('Local notification error: $e');
      lastTestError = '${lastTestError ?? ''} | Local: ${e.toString()}';
      return false;
    }
  }
}
