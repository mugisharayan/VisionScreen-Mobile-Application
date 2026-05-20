// Integration test: screening, report and referral decision pipeline.
//
// A completed screening produces per-eye visual-acuity values. Those flow
// through PatientReportService.buildEyeResults, are interpreted by
// VisualAcuity, and finally drive the referral decision. The referral rule
// mirrors ScreeningFlowController.needsReferral: refer when any tested eye
// has logMAR > 0.5 (or an unparseable value).

import 'package:flutter_test/flutter_test.dart';
import 'package:visionscreen/services/patient_report_service.dart';
import 'package:visionscreen/utils/visual_acuity.dart';

/// Referral decision, kept identical to ScreeningFlowController.needsReferral.
String decideOutcome(List<Map<String, dynamic>> eyeResults) {
  final refer = eyeResults.any((result) {
    final value = double.tryParse(result['logmar'] as String);
    return value == null || value > 0.5;
  });
  return refer ? 'refer' : 'pass';
}

void main() {
  group('Screening pipeline integration', () {
    test('a patient with normal vision passes end-to-end', () {
      final eyes = PatientReportService.buildEyeResults(
        latestScreening: <String, dynamic>{
          'od_logmar': '0.0',
          'os_logmar': '0.2',
        },
        fallbackOdSnellen: '6/6',
        fallbackOsSnellen: '6/6',
      );

      expect(eyes.map((e) => e['eye']), <String>['OD', 'OS']);
      expect(VisualAcuity.classification(eyes.first['logmar'] as String),
          'Normal');
      expect(decideOutcome(eyes), 'pass');
    });

    test('moderate impairment in one eye triggers a referral', () {
      final eyes = PatientReportService.buildEyeResults(
        latestScreening: <String, dynamic>{
          'od_logmar': '0.2',
          'os_logmar': '0.8',
        },
        fallbackOdSnellen: '6/6',
        fallbackOsSnellen: '6/6',
      );

      expect(VisualAcuity.classification('0.8'),
          'Severe Visual Impairment');
      expect(decideOutcome(eyes), 'refer');
    });

    test('Snellen-only screenings are converted then evaluated', () {
      final eyes = PatientReportService.buildEyeResults(
        latestScreening: <String, dynamic>{
          'od_logmar': '',
          'os_logmar': '',
          'od_snellen': '6/60',
          'os_snellen': '6/9',
        },
        fallbackOdSnellen: '6/6',
        fallbackOsSnellen: '6/6',
      );

      expect(eyes.first['logmar'], '1.0'); // 6/60 maps to logMAR 1.0
      expect(decideOutcome(eyes), 'refer');
    });

    test('the 0.5 logMAR boundary passes (referral is strictly > 0.5)', () {
      final eyes = PatientReportService.buildEyeResults(
        latestScreening: <String, dynamic>{
          'od_logmar': '0.5',
          'os_logmar': '0.5',
        },
        fallbackOdSnellen: '6/6',
        fallbackOsSnellen: '6/6',
      );

      expect(VisualAcuity.classification('0.5'),
          'Moderate Visual Impairment');
      expect(decideOutcome(eyes), 'pass');
    });

    test('an untestable eye is treated as a referral', () {
      final eyes = <Map<String, dynamic>>[
        <String, dynamic>{'eye': 'OD', 'logmar': 'can-not-tell', 'cantTell': 3},
      ];
      expect(decideOutcome(eyes), 'refer');
    });
  });
}
