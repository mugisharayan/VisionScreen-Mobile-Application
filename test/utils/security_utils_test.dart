import 'package:flutter_test/flutter_test.dart';
import 'package:visionscreen/utils/security_utils.dart';

void main() {
  group('SecurityUtils.hashPassword', () {
    test('stores the value as "salt:hash"', () {
      final stored = SecurityUtils.hashPassword('S3cret!');
      final parts = stored.split(':');
      expect(parts.length, 2);
      expect(parts[0].length, 64); // 32-byte salt as hex
      expect(parts[1], isNotEmpty);
    });

    test('uses a fresh random salt for every call', () {
      final a = SecurityUtils.hashPassword('same-password');
      final b = SecurityUtils.hashPassword('same-password');
      expect(a, isNot(equals(b)));
    });
  });

  group('SecurityUtils.verifyPassword', () {
    test('accepts the correct password', () {
      final stored = SecurityUtils.hashPassword('correct horse');
      expect(SecurityUtils.verifyPassword('correct horse', stored), isTrue);
    });

    test('rejects an incorrect password', () {
      final stored = SecurityUtils.hashPassword('correct horse');
      expect(SecurityUtils.verifyPassword('wrong horse', stored), isFalse);
    });

    test('rejects a malformed stored value', () {
      expect(SecurityUtils.verifyPassword('x', 'no-colon-here'), isFalse);
      expect(SecurityUtils.verifyPassword('x', 'a:b:c'), isFalse);
    });
  });

  group('SecurityUtils.randomToken', () {
    test('returns a hex token of the requested byte length', () {
      expect(SecurityUtils.randomToken().length, 48); // 24 bytes default
      expect(SecurityUtils.randomToken(16).length, 32);
    });

    test('produces unique tokens', () {
      final tokens = <String>{
        for (var i = 0; i < 500; i++) SecurityUtils.randomToken(),
      };
      expect(tokens.length, 500);
    });
  });

  group('SecurityUtils.constantTimeEquals', () {
    test('is true only for identical strings', () {
      expect(SecurityUtils.constantTimeEquals('abc123', 'abc123'), isTrue);
      expect(SecurityUtils.constantTimeEquals('abc123', 'abc124'), isFalse);
    });

    test('is false for strings of different lengths', () {
      expect(SecurityUtils.constantTimeEquals('abc', 'abcd'), isFalse);
    });
  });
}
