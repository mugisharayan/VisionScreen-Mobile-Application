import '../repositories/screening_repository.dart';
import 'chw_profile_preferences.dart';
import '../utils/app_constants.dart';
import '../utils/visual_acuity.dart';
import 'pdf_service.dart';

class PatientReportRequest {
  const PatientReportRequest({
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientVillage,
    required this.patientPhone,
    required this.outcome,
    required this.fallbackOdSnellen,
    required this.fallbackOsSnellen,
    required this.conditions,
    this.facility,
  });

  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientVillage;
  final String patientPhone;
  final String outcome;
  final String fallbackOdSnellen;
  final String fallbackOsSnellen;
  final String? facility;
  final List<String> conditions;
}

class PatientReportResult {
  const PatientReportResult({
    required this.filePath,
    required this.subject,
  });

  final String filePath;
  final String subject;
}

class PatientReportService {
  PatientReportService._();

  static const _missingVisualAcuityValues = <String>{
    '',
    '�',
    'Not tested',
  };

  static Future<PatientReportResult?> generatePatientPdf(
    PatientReportRequest request,
  ) async {
    if (request.outcome == AppStrings.outcomePending) {
      return null;
    }

    final screenings = await ScreeningRepository.instance.getScreeningsForPatient(
      request.patientId,
    );
    final latest = screenings.isNotEmpty ? screenings.first : null;
    final profile = await ChwProfilePreferences.load();
    final screeningDate =
        (latest?['screening_date'] as String? ??
                DateTime.now().toIso8601String())
            .substring(0, 10);

    final patient = <String, String>{
      'name': request.patientName,
      'id': request.patientId,
      'age': request.patientAge.toString(),
      'gender': request.patientGender,
      'village': request.patientVillage,
      'phone': request.patientPhone,
    };

    final eyeResults = buildEyeResults(
      latestScreening: latest,
      fallbackOdSnellen: request.fallbackOdSnellen,
      fallbackOsSnellen: request.fallbackOsSnellen,
    );

    final isReferral = request.outcome == AppStrings.outcomeRefer;
    final filePath = isReferral
        ? await PdfService.generateReferralPdf(
            patient: patient,
            eyeResults: eyeResults,
            screeningDate: screeningDate,
            facility: request.facility ?? 'Nearest Eye Clinic',
            chwName: profile.name,
            chwTitle: profile.title,
            chwId: profile.chwId,
            appointmentDate: latest?['appointment_date'] as String?,
            conditions: request.conditions,
            language: profile.referralLanguage,
          )
        : await PdfService.generatePassResultPdf(
            patient: patient,
            eyeResults: eyeResults,
            screeningDate: screeningDate,
            chwName: profile.name,
            chwTitle: profile.title,
            chwId: profile.chwId,
            conditions: request.conditions,
            language: profile.referralLanguage,
          );

    final subjectPrefix = isReferral ? 'Referral Letter' : 'Screening Result';
    return PatientReportResult(
      filePath: filePath,
      subject: '$subjectPrefix - ${request.patientName}',
    );
  }

  static List<Map<String, dynamic>> buildEyeResults({
    required Map<String, dynamic>? latestScreening,
    required String fallbackOdSnellen,
    required String fallbackOsSnellen,
  }) {
    final eyeResults = <Map<String, dynamic>>[];
    if (latestScreening != null) {
      final odLogmar = (latestScreening['od_logmar'] as String? ?? '').trim();
      final osLogmar = (latestScreening['os_logmar'] as String? ?? '').trim();
      if (odLogmar.isNotEmpty) {
        eyeResults.add({'eye': 'OD', 'logmar': odLogmar, 'cantTell': 0});
      }
      if (osLogmar.isNotEmpty) {
        eyeResults.add({'eye': 'OS', 'logmar': osLogmar, 'cantTell': 0});
      }
      if (eyeResults.isNotEmpty) {
        return eyeResults;
      }

      _appendSnellenFallback(
        eyeResults: eyeResults,
        eye: 'OD',
        snellen: (latestScreening['od_snellen'] as String? ?? '').trim(),
      );
      _appendSnellenFallback(
        eyeResults: eyeResults,
        eye: 'OS',
        snellen: (latestScreening['os_snellen'] as String? ?? '').trim(),
      );
    }

    if (eyeResults.isNotEmpty) {
      return eyeResults;
    }

    _appendSnellenFallback(
      eyeResults: eyeResults,
      eye: 'OD',
      snellen: fallbackOdSnellen.trim(),
    );
    _appendSnellenFallback(
      eyeResults: eyeResults,
      eye: 'OS',
      snellen: fallbackOsSnellen.trim(),
    );
    return eyeResults;
  }

  static void _appendSnellenFallback({
    required List<Map<String, dynamic>> eyeResults,
    required String eye,
    required String snellen,
  }) {
    if (_missingVisualAcuityValues.contains(snellen)) {
      return;
    }
    eyeResults.add({
      'eye': eye,
      'logmar': VisualAcuity.toLogmar(snellen),
      'cantTell': 0,
    });
  }
}
