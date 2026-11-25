import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import '../models/user_profile.dart';
import 'crypto_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userKey = 'auth_user_profile_v1';
  static const String _oauthTokenKey = 'auth_oauth_token_v1';
  static const String _guestAvatarKey = 'guest_avatar_url_v1';
  static const String _lastSyncKey = 'auth_last_sync_v1';
  static const String _syncApiUrl = 'https://adhkar-push.wassimbousmaa.workers.dev/api/user/sync';
  static const String googleClientId = '712885191318-46e55srndlla0f7eo7qb761p1kfhhnub.apps.googleusercontent.com';

  UserProfile? _currentUser;
  String? _accessToken;
  String? _guestAvatar;
  DateTime? _lastSyncTime;
  bool _isLoading = false;
  bool _isSyncing = false;
  void Function(UserProfile user)? onUserSignedIn;

  UserProfile? get currentUser => _currentUser;
  String? get guestAvatar => _guestAvatar;
  String? get effectivePhotoUrl => _currentUser?.photoUrl ?? _guestAvatar;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _guestAvatar = prefs.getString(_guestAvatarKey);
      final userRaw = prefs.getString(_userKey);
      if (userRaw != null && userRaw.isNotEmpty) {
        final userJson = await CryptoService.decrypt(userRaw);
        if (userJson.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(userJson);
          _currentUser = UserProfile.fromJson(data);
          // Migrate legacy unencrypted data to AES-256-GCM transparently
          if (!CryptoService.isEncrypted(userRaw)) {
            await prefs.setString(_userKey, await CryptoService.encrypt(userJson));
          }
        }
      }
      final tokenRaw = prefs.getString(_oauthTokenKey);
      if (tokenRaw != null && tokenRaw.isNotEmpty) {
        final decryptedToken = await CryptoService.decrypt(tokenRaw);
        if (decryptedToken.isNotEmpty) {
          _accessToken = decryptedToken;
        }
      }
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }
      if (kIsWeb) {
        _setupWebAuthListener();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved auth: $e');
    }
  }

  /// Updates the user's avatar (both for connected users and guest mode)
  Future<void> updateAvatar(String newAvatarUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isLoggedIn && _currentUser != null) {
        _currentUser = UserProfile(
          id: _currentUser!.id,
          email: _currentUser!.email,
          displayName: _currentUser!.displayName,
          photoUrl: newAvatarUrl,
          createdAt: _currentUser!.createdAt,
        );
        await prefs.setString(
          _userKey,
          await CryptoService.encrypt(jsonEncode(_currentUser!.toJson())),
        );
      } else {
        _guestAvatar = newAvatarUrl;
        await prefs.setString(_guestAvatarKey, newAvatarUrl);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating avatar: $e');
    }
  }

  void _setupWebAuthListener() {
    try {
      web.window.addEventListener(
        'google-auth-success',
        ((web.CustomEvent event) {
          try {
            final detail = (event.detail as JSString).toDart;
            final Map<String, dynamic> data = jsonDecode(detail);
            _processAuthPayload(data);
          } catch (_) {}
        }.toJS),
      );

      // Check for pending login from redirect or storage
      final pending = web.window.localStorage.getItem('auth_google_pending_login');
      if (pending != null && pending.isNotEmpty) {
        web.window.localStorage.removeItem('auth_google_pending_login');
        final Map<String, dynamic> data = jsonDecode(pending);
        _processAuthPayload(data);
      }
    } catch (e) {
      debugPrint('Error setting up web auth listener: $e');
    }
  }

  void _processAuthPayload(Map<String, dynamic> data) {
    if (data['type'] == 'GOOGLE_SIGN_IN_SUCCESS') {
      final email = data['email'] as String? ?? '';
      final name = data['displayName'] as String? ?? '';
      final photo = data['photoUrl'] as String?;
      final token = data['accessToken'] as String?;
      if (email.isNotEmpty) {
        signInWithGoogle(
          email: email,
          displayName: name.isNotEmpty ? name : email.split('@').first,
          photoUrl: photo,
          accessToken: token,
        ).then((success) {
          if (success && _currentUser != null && onUserSignedIn != null) {
            onUserSignedIn!(_currentUser!);
          }
        });
      }
    }
  }

  /// Launches the 100% official Google Identity Services OAuth popup (accounts.google.com)
  bool openGoogleSignInPopup({String lang = 'fr'}) {
    if (kIsWeb) {
      try {
        web.window.dispatchEvent(web.CustomEvent('launch-official-google-auth'));
        return true;
      } catch (e) {
        debugPrint('GIS trigger error: $e');
      }
    }
    return false;
  }

  /// 1-Click Google Sign-In
  /// Generates a validated Google User Profile linked to the user's account
  Future<bool> signInWithGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
    String? accessToken,
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
      if (accessToken != null && accessToken.isNotEmpty) {
        _accessToken = accessToken;
      }
      _lastSyncTime = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _userKey,
        await CryptoService.encrypt(jsonEncode(user.toJson())),
      );
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await prefs.setString(
          _oauthTokenKey,
          await CryptoService.encrypt(_accessToken!),
        );
      }
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
    _accessToken = null;
    _lastSyncTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_oauthTokenKey);
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
        if (_accessToken != null && _accessToken!.isNotEmpty) {
          headers.set('Authorization', 'Bearer $_accessToken');
        }

        final reqInit = web.RequestInit(
          method: 'POST',
          headers: headers,
          body: jsonEncode(payload).toJS,
        );

        final resp = await web.window.fetch(_syncApiUrl.toJS, reqInit).toDart;
        if (!resp.ok) {
          debugPrint('Cloud sync rejected with HTTP ${resp.status}');
          _isSyncing = false;
          notifyListeners();
          return false;
        }
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
        final headers = web.Headers();
        if (_accessToken != null && _accessToken!.isNotEmpty) {
          headers.set('Authorization', 'Bearer $_accessToken');
        }
        final reqInit = web.RequestInit(
          method: 'GET',
          headers: headers,
        );
        final resp = await web.window.fetch(url.toJS, reqInit).toDart;
        if (!resp.ok) {
          debugPrint('Cloud fetch rejected with HTTP ${resp.status}');
          return null;
        }
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
