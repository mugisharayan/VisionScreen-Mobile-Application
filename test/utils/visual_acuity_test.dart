import 'package:flutter_test/flutter_test.dart';
import 'package:visionscreen/utils/visual_acuity.dart';

void main() {
  group('VisualAcuity.toSnellen', () {
    test('maps common LogMAR values to Snellen values', () {
      expect(VisualAcuity.toSnellen('0.0'), '6/6');
      expect(VisualAcuity.toSnellen('0.3'), '6/12');
      expect(VisualAcuity.toSnellen('1.0'), '6/60');
    });

    test('returns the original value when LogMAR is invalid', () {
      expect(VisualAcuity.toSnellen('not-a-number'), 'not-a-number');
    });
  });

  group('VisualAcuity.toLogmar', () {
    test('maps known Snellen values to LogMAR values', () {
      expect(VisualAcuity.toLogmar('6/6'), '0.0');
      expect(VisualAcuity.toLogmar('6/24'), '0.6');
      expect(VisualAcuity.toLogmar('6/120'), '1.3');
    });

    test('uses the default fallback for unknown Snellen values', () {
      expect(VisualAcuity.toLogmar('6/15'), '0.5');
    });
  });

  group('VisualAcuity.classification', () {
    test('returns canonical visual acuity bands', () {
      expect(VisualAcuity.classification('0.0'), 'Normal');
      expect(VisualAcuity.classification('0.3'), 'Near Normal');
      expect(
        VisualAcuity.classification('0.5'),
        'Moderate Visual Impairment',
      );
      expect(
        VisualAcuity.classification('0.8'),
        'Severe Visual Impairment',
      );
      expect(VisualAcuity.classification('1.3'), 'Blind');
    });
  });
}
