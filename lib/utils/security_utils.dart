import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Security utilities for password hashing and verification.
///
/// Uses PBKDF2-style salted SHA-256 to protect passwords at rest.
/// Each password is stored as "salt:hash" so the salt is recoverable
/// for verification without a separate column.
class SecurityUtils {
  SecurityUtils._();

  static const _saltLength = 32; // bytes → 64 hex chars
  static const _iterations = 10000;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Hash a plain-text password. Returns "salt:hash".
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = _pbkdf2(password, salt, _iterations);
    return '$salt:$hash';
  }

  /// Generate a cryptographically random opaque token, [byteLength] bytes
  /// rendered as hex. Suitable for short-lived single-use tokens like
  /// password-reset handles.
  static String randomToken([int byteLength = 24]) {
    final rng = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Verify a plain-text password against a stored "salt:hash" value.
  static bool verifyPassword(String plainText, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expectedHash = parts[1];
    final actualHash = _pbkdf2(plainText, salt, _iterations);
    return constantTimeEquals(actualHash, expectedHash);
  }

  /// Constant-time string comparison for secrets such as password hashes and
  /// short-lived reset tokens.
  static bool constantTimeEquals(String a, String b) {
    final maxLength = a.length > b.length ? a.length : b.length;
    var result = a.length ^ b.length;
    for (var i = 0; i < maxLength; i++) {
      final ac = i < a.length ? a.codeUnitAt(i) : 0;
      final bc = i < b.length ? b.codeUnitAt(i) : 0;
      result |= ac ^ bc;
    }
    return result == 0;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(_saltLength, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Simplified PBKDF2 using HMAC-SHA256.
  /// Runs [iterations] rounds of SHA-256 keyed with the salt.
  static String _pbkdf2(String password, String salt, int iterations) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    // Initial HMAC-SHA256
    var hmac = Hmac(sha256, passwordBytes);
    var result = hmac.convert(saltBytes).bytes;

    // Iterate
    for (var i = 1; i < iterations; i++) {
      hmac = Hmac(sha256, passwordBytes);
      result = hmac.convert(result).bytes;
    }

    return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
