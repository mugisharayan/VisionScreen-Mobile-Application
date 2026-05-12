import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../repositories/campaign_repository.dart';
import '../../repositories/screening_repository.dart';
import '../../services/patient_report_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/page_transitions.dart';
import '../../screens/bulk_mode_screen.dart';
import '../../screens/new_screening_screen.dart';
import 'patient_list_item.dart';

class PatientReferralStatusOption {
  const PatientReferralStatusOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

const patientReferralStatusOptions = [
  PatientReferralStatusOption(
    value: 'pending',
    label: 'Pending',
    icon: Icons.schedule_rounded,
    color: Color(0xFFF59E0B),
  ),
  PatientReferralStatusOption(
    value: 'notified',
    label: 'Notified',
    icon: Icons.notifications_active_rounded,
    color: Color(0xFF3B82F6),
  ),
  PatientReferralStatusOption(
    value: 'attended',
    label: 'Attended',
    icon: Icons.check_circle_outline_rounded,
    color: Color(0xFF0D9488),
  ),
  PatientReferralStatusOption(
    value: 'completed',
    label: 'Completed',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF22C55E),
  ),
  PatientReferralStatusOption(
    value: 'overdue',
    label: 'Overdue',
    icon: Icons.error_rounded,
    color: Color(0xFFEF4444),
  ),
  PatientReferralStatusOption(
    value: 'cancelled',
    label: 'Cancelled',
    icon: Icons.cancel_rounded,
    color: Colors.grey,
  ),
];

class PatientActions {
  PatientActions._();

  static Future<void> exportReport(
    BuildContext context,
    PatientListItem patient, {
    bool closeSheet = false,
  }) async {
    if (closeSheet && context.mounted) {
      Navigator.pop(context);
    }
    _showSnackBar(
      context,
      content: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Generating PDF...',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D9488),
      duration: const Duration(seconds: 30),
    );

    try {
      if (!context.mounted) {
        return;
      }
      if (patient.outcome == 'pending') {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar(
          context,
          content: Text(
            'No screening results yet for ${patient.name}.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFF59E0B),
        );
        return;
      }

      final report = await PatientReportService.generatePatientPdf(
        PatientReportRequest(
          patientId: patient.id,
          patientName: patient.name,
          patientAge: patient.age,
          patientGender: patient.gender,
          patientVillage: patient.village,
          patientPhone: patient.phone,
          outcome: patient.outcome,
          fallbackOdSnellen: patient.od,
          fallbackOsSnellen: patient.os,
          facility: patient.facility,
          conditions: patient.safeConditions,
        ),
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (report == null) {
        return;
      }
      await PdfService.openOrShare(
        context,
        report.filePath,
        report.subject,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar(
        context,
        content: Text(
          'PDF failed: $error',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF4444),
      );
    }
  }

  static Future<void> shareToWhatsApp(
    BuildContext context,
    PatientListItem patient,
  ) async {
    final phone = normaliseWhatsAppPhone(patient.phone);
    final encoded = Uri.encodeComponent(patient.whatsappMessage);
    final uri = phone.isNotEmpty
        ? Uri.parse('whatsapp://send?phone=$phone&text=$encoded')
        : Uri.parse('whatsapp://send?text=$encoded');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showErrorSnackBar(
        context,
        title: 'WhatsApp not available',
        message: 'Could not open WhatsApp on this device.',
      );
    }
  }

  static Future<void> callPatient(
    BuildContext context,
    PatientListItem patient,
  ) async {
    if (patient.phone.isEmpty) {
      _showSnackBar(
        context,
        content: Text(
          'No phone number for ${patient.name}.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF59E0B),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: patient.phone);
    if (!await launchUrl(uri) && context.mounted) {
      _showErrorSnackBar(
        context,
        title: 'Call failed',
        message:
            'Unable to dial ${patient.name}. Please check your device settings.',
      );
    }
  }

  static Future<void> openScreening(
    BuildContext context,
    PatientListItem patient,
  ) async {
    if (patient.campaignId != null) {
      final campaigns = await CampaignRepository.instance.getAllCampaigns();
      final campaign = campaigns.firstWhere(
        (entry) => entry['id'] == patient.campaignId,
        orElse: () => <String, dynamic>{},
      );
      if (!context.mounted) {
        return;
      }
      await Navigator.push(
        context,
        VsPageRoute(
          builder: (_) => BulkModeScreen(
            existingCampaignId: patient.campaignId,
            existingCampaignName: campaign['name'] as String? ?? '',
            existingCampaignLocation: campaign['location'] as String? ?? '',
            existingPatientId: patient.id,
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      VsPageRoute(
        builder: (_) => NewScreeningScreen(existingPatientId: patient.id),
      ),
    );
  }

  static Future<void> updateReferralStatus(
    PatientListItem patient,
    String status,
  ) async {
    final screenings = await ScreeningRepository.instance.getScreeningsForPatient(
      patient.id,
    );
    if (screenings.isEmpty) {
      return;
    }
    await ScreeningRepository.instance.updateReferralStatus(
      screenings.first['id'] as int,
      status,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required Widget content,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      ),
    );
  }

  static void _showErrorSnackBar(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackBar(
      context,
      content: Row(
        children: [
          const Icon(Icons.error_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEF4444),
    );
  }
}
