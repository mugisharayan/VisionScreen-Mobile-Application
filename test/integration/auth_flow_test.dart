// Integration test: registration, login and password-reset workflow.
//
// This exercises several units working together the way the auth repository
// uses them in production: SecurityUtils.hashPassword for storage at rest,
// SecurityUtils.verifyPassword for login, and SecurityUtils.randomToken +
// constantTimeEquals for the single-use password-reset handle.

import 'package:flutter_test/flutter_test.dart';
import 'package:visionscreen/utils/security_utils.dart';

/// Minimal in-memory stand-in for the accounts table, just enough to drive
/// the end-to-end flow without a database.
class _FakeAccountStore {
  final Map<String, String> _passwordHashes = <String, String>{};
  final Map<String, String> _resetTokens = <String, String>{};

  void register(String email, String password) {
    _passwordHashes[email] = SecurityUtils.hashPassword(password);
  }

  bool login(String email, String password) {
    final stored = _passwordHashes[email];
    if (stored == null) return false;
    return SecurityUtils.verifyPassword(password, stored);
  }

  String issueResetToken(String email) {
    final token = SecurityUtils.randomToken();
    _resetTokens[email] = token;
    return token;
  }

  bool resetPassword(String email, String presentedToken, String newPassword) {
    final expected = _resetTokens[email];
    if (expected == null) return false;
    if (!SecurityUtils.constantTimeEquals(presentedToken, expected)) {
      return false;
    }
    _passwordHashes[email] = SecurityUtils.hashPassword(newPassword);
    _resetTokens.remove(email); // single use
    return true;
  }
}

void main() {
  group('Authentication flow integration', () {
    late _FakeAccountStore store;
    const email = 'chw@example.org';

    setUp(() => store = _FakeAccountStore());

    test('a registered health worker can log in with the right password', () {
      store.register(email, 'OpenSesame1');
      expect(store.login(email, 'OpenSesame1'), isTrue);
    });

    test('login fails for a wrong password and unknown account', () {
      store.register(email, 'OpenSesame1');
      expect(store.login(email, 'openSesame1'), isFalse);
      expect(store.login('ghost@example.org', 'OpenSesame1'), isFalse);
    });

    test('password reset issues a token and rotates the credential', () {
      store.register(email, 'OldPass123');
      final token = store.issueResetToken(email);

      expect(store.resetPassword(email, 'tampered-token', 'NewPass456'),
          isFalse);
      expect(store.resetPassword(email, token, 'NewPass456'), isTrue);

      expect(store.login(email, 'OldPass123'), isFalse);
      expect(store.login(email, 'NewPass456'), isTrue);
    });

    test('a reset token cannot be replayed', () {
      store.register(email, 'OldPass123');
      final token = store.issueResetToken(email);
      expect(store.resetPassword(email, token, 'NewPass456'), isTrue);
      expect(store.resetPassword(email, token, 'Another789'), isFalse);
    });
  });
}
