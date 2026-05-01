import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Security utilities for password hashing and verification.
///
/// Uses PBKDF2-style salted SHA-256 to protect passwords at rest.
/// Each password is stored as "salt:hash" so the salt is recoverable
/// for verification without a separate column.
///
/// Migration: existing unsalted SHA-256 hashes (64 hex chars, no colon)
/// are detected and re-hashed on first successful login.
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

  /// Verify a plain-text password against a stored hash.
  ///
  /// Supports both the new "salt:hash" format and the legacy
  /// unsalted SHA-256 format (64 hex chars) for backward compatibility.
  static bool verifyPassword(String plainText, String stored) {
    if (_isLegacyHash(stored)) {
      // Legacy: plain SHA-256 without salt
      final bytes = utf8.encode(plainText);
      return sha256.convert(bytes).toString() == stored;
    }
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expectedHash = parts[1];
    final actualHash = _pbkdf2(plainText, salt, _iterations);
    return _constantTimeEquals(actualHash, expectedHash);
  }

  /// Returns true if the stored hash is in the legacy (unsalted) format.
  /// Use this to trigger a re-hash on successful login.
  static bool needsRehash(String stored) => _isLegacyHash(stored);

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
    final saltBytes     = utf8.encode(salt);

    // Initial HMAC-SHA256
    var hmac = Hmac(sha256, passwordBytes);
    var result = hmac.convert(saltBytes).bytes;

    // Iterate
    for (var i = 1; i < iterations; i++) {
      hmac   = Hmac(sha256, passwordBytes);
      result = hmac.convert(result).bytes;
    }

    return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Constant-time string comparison to prevent timing attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Legacy hash: exactly 64 hex chars, no colon separator.
  static bool _isLegacyHash(String stored) {
    return !stored.contains(':') && stored.length == 64;
  }
}
