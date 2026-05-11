import 'dart:math';

class IdUtils {
  IdUtils._();

  static final Random _rng = Random.secure();

  static String generate(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = List.generate(
      10,
      (_) => _alphabet[_rng.nextInt(_alphabet.length)],
    ).join();
    return '$prefix-$now$entropy';
  }

  static String facilityId({required String center, required String district}) {
    final normalizedCenter = _slugify(center);
    final normalizedDistrict = _slugify(district);
    return 'facility-$normalizedDistrict-$normalizedCenter';
  }

  static String _slugify(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return cleaned.isEmpty ? 'unknown' : cleaned;
  }

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
}
