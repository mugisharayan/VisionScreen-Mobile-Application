import 'package:flutter_test/flutter_test.dart';
import 'package:visionscreen/services/patient_report_service.dart';

void main() {
  group('PatientReportService.buildEyeResults', () {
    test('prefers LogMAR values from the latest screening', () {
      final results = PatientReportService.buildEyeResults(
        latestScreening: <String, dynamic>{
          'od_logmar': '0.3',
          'os_logmar': '0.5',
          'od_snellen': '6/12',
          'os_snellen': '6/18',
        },
        fallbackOdSnellen: '6/24',
        fallbackOsSnellen: '6/36',
      );

      expect(results, <Map<String, dynamic>>[
        <String, dynamic>{'eye': 'OD', 'logmar': '0.3', 'cantTell': 0},
        <String, dynamic>{'eye': 'OS', 'logmar': '0.5', 'cantTell': 0},
      ]);
    });

    test('falls back to Snellen values when LogMAR is unavailable', () {
      final results = PatientReportService.buildEyeResults(
        latestScreening: <String, dynamic>{
          'od_logmar': '',
          'os_logmar': '',
          'od_snellen': '6/24',
          'os_snellen': '6/60',
        },
        fallbackOdSnellen: '6/6',
        fallbackOsSnellen: '6/9',
      );

      expect(results, <Map<String, dynamic>>[
        <String, dynamic>{'eye': 'OD', 'logmar': '0.6', 'cantTell': 0},
        <String, dynamic>{'eye': 'OS', 'logmar': '1.0', 'cantTell': 0},
      ]);
    });

    test('uses patient-level fallback Snellen values when needed', () {
      final results = PatientReportService.buildEyeResults(
        latestScreening: null,
        fallbackOdSnellen: '6/12',
        fallbackOsSnellen: 'Not tested',
      );

      expect(results, <Map<String, dynamic>>[
        <String, dynamic>{'eye': 'OD', 'logmar': '0.3', 'cantTell': 0},
      ]);
    });
  });
}
