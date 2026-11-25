import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('adhkarCryptoEncrypt')
external JSPromise<JSString> _jsCryptoEncrypt(JSString plaintext);

@JS('adhkarCryptoDecrypt')
external JSPromise<JSString> _jsCryptoDecrypt(JSString payload);

/// Client-side AES-256-GCM encryption service backed by the browser's
/// native Web Crypto API (`window.crypto.subtle` + PBKDF2-SHA256).
class CryptoService {
  static const String prefix = 'enc:v1:';

  /// Returns true if [value] is already encrypted with this service's format.
  static bool isEncrypted(String? value) {
    return value != null && value.startsWith(prefix);
  }

  /// Encrypts [plaintext] using AES-256-GCM and returns `enc:v1:<iv>:<ciphertext>`.
  /// Falls back to [plaintext] only on non-web platforms or if Web Crypto is unavailable.
  static Future<String> encrypt(String plaintext) async {
    if (!kIsWeb || plaintext.isEmpty) return plaintext;
    try {
      final result = await _jsCryptoEncrypt(plaintext.toJS).toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('CryptoService encrypt error: $e');
      return plaintext;
    }
  }

  /// Decrypts an `enc:v1:...` payload back to plaintext.
  /// If [storedValue] is legacy unencrypted data (does not start with `enc:v1:`),
  /// returns it transparently so existing user data migrates without loss.
  static Future<String> decrypt(String storedValue) async {
    if (!kIsWeb || !isEncrypted(storedValue)) return storedValue;
    try {
      final result = await _jsCryptoDecrypt(storedValue.toJS).toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('CryptoService decrypt error: $e');
      return '';
    }
  }
}
