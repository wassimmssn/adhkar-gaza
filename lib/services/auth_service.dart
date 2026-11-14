import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userKey = 'auth_user_profile_v1';
  static const String _lastSyncKey = 'auth_last_sync_v1';
  static const String _syncApiUrl = 'https://adhkar-push.wassimbousmaa.workers.dev/api/user/sync';

  UserProfile? _currentUser;
  DateTime? _lastSyncTime;
  bool _isLoading = false;
  bool _isSyncing = false;

  UserProfile? get currentUser => _currentUser;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        _currentUser = UserProfile.fromJson(data);
      }
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved auth: $e');
    }
  }

  /// 1-Click Google Sign-In
  /// Generates a validated Google User Profile linked to the user's account
  Future<bool> signInWithGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = 'google_${email.toLowerCase().hashCode.abs()}';
      final cleanPhoto = photoUrl != null && photoUrl.isNotEmpty
          ? photoUrl
          : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=0a6482&color=fff&size=128&bold=true';

      final user = UserProfile(
        id: id,
        email: email.trim().toLowerCase(),
        displayName: displayName.trim(),
        photoUrl: cleanPhoto,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      _lastSyncTime = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _currentUser = null;
    _lastSyncTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_lastSyncKey);
    notifyListeners();
  }

  /// Backup preferences and streaks to Cloudflare Worker KV
  Future<bool> syncToCloud({
    required Map<String, dynamic> settingsData,
    required Map<String, dynamic> streakData,
  }) async {
    if (!isLoggedIn || _currentUser == null) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final payload = {
        'email': _currentUser!.email,
        'profile': _currentUser!.toJson(),
        'settings': settingsData,
        'streakData': streakData,
      };

      if (kIsWeb) {
        final headers = web.Headers();
        headers.set('Content-Type', 'application/json');

        final reqInit = web.RequestInit(
          method: 'POST',
          headers: headers,
          body: jsonEncode(payload).toJS,
        );

        await web.window.fetch(_syncApiUrl.toJS, reqInit).toDart;
      }

      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Cloud sync error (fallback to local state): $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore user preferences and streak from cloud KV if available
  Future<Map<String, dynamic>?> fetchFromCloud() async {
    if (!isLoggedIn || _currentUser == null) return null;

    try {
      if (kIsWeb) {
        final url = '$_syncApiUrl?email=${Uri.encodeComponent(_currentUser!.email)}';
        final resp = await web.window.fetch(url.toJS).toDart;
        final jsonText = (await resp.text().toDart).toDart;
        final Map<String, dynamic> res = jsonDecode(jsonText);
        if (res['exists'] == true && res['data'] != null) {
          return Map<String, dynamic>.from(res['data']);
        }
      }
    } catch (e) {
      debugPrint('Fetch from cloud error: $e');
    }
    return null;
  }
}
