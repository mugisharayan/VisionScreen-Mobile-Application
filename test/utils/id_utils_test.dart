import 'package:flutter_test/flutter_test.dart';
import 'package:visionscreen/utils/id_utils.dart';

void main() {
  group('IdUtils.generate', () {
    test('prefixes the identifier and keeps the separator', () {
      final id = IdUtils.generate('patient');
      expect(id.startsWith('patient-'), isTrue);
      expect(id.length, greaterThan('patient-'.length));
    });

    test('produces unique identifiers across many calls', () {
      final ids = <String>{
        for (var i = 0; i < 1000; i++) IdUtils.generate('p'),
      };
      expect(ids.length, 1000);
    });
  });

  group('IdUtils.facilityId', () {
    test('slugifies centre and district into a stable id', () {
      expect(
        IdUtils.facilityId(center: 'Mulago HC IV', district: 'Kampala'),
        'facility-kampala-mulago-hc-iv',
      );
    });

    test('collapses repeated separators and trims edges', () {
      expect(
        IdUtils.facilityId(center: '  St. Mary\'s  ', district: 'Wakiso!!'),
        'facility-wakiso-st-mary-s',
      );
    });

    test('falls back to "unknown" for empty components', () {
      expect(
        IdUtils.facilityId(center: '', district: '@@@'),
        'facility-unknown-unknown',
      );
    });
  });
}
