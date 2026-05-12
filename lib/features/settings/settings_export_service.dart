import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../db/database_helper.dart';
import '../../repositories/campaign_repository.dart';
import '../../repositories/screening_repository.dart';

class SettingsExportProfile {
  const SettingsExportProfile({
    required this.chwName,
    required this.chwCenter,
    required this.chwDistrict,
    required this.chwId,
  });

  final String chwName;
  final String chwCenter;
  final String chwDistrict;
  final String chwId;

  String get displayChwName => chwName.isNotEmpty ? chwName : 'CHW';
  String get displayCenterOrDistrict =>
      chwCenter.isNotEmpty ? chwCenter : chwDistrict;
  String get displayBadgeId => chwId.isNotEmpty ? chwId : 'N/A';
}

class SettingsExportService {
  static Future<File?> exportPatientRecordsPdf(
    SettingsExportProfile profile,
  ) async {
    final database = await DatabaseHelper.instance.db;
    final patients = await database.rawQuery('''
      SELECT p.*,
             s.od_snellen, s.os_snellen, s.ou_near_snellen,
             s.od_logmar, s.os_logmar,
             s.outcome, s.referral_facility, s.referral_status,
             s.appointment_date, s.screening_date, s.chw_name
      FROM patients p
      LEFT JOIN screenings s ON s.id = (
        SELECT id FROM screenings WHERE patient_id = p.id AND deleted_at IS NULL
        ORDER BY screening_date DESC LIMIT 1
      )
      WHERE p.deleted_at IS NULL
      ORDER BY p.created_at DESC
    ''');

    if (patients.isEmpty) return null;

    final teal = PdfColor.fromHex('#0D9488');
    final teal2 = PdfColor.fromHex('#CCFBF1');
    final g900 = PdfColor.fromHex('#0F172A');
    final g700 = PdfColor.fromHex('#334155');
    final g500 = PdfColor.fromHex('#64748B');
    final g200 = PdfColor.fromHex('#E2E8F0');
    final g50 = PdfColor.fromHex('#F8FAFC');
    final green = PdfColor.fromHex('#16A34A');
    final greenL = PdfColor.fromHex('#DCFCE7');
    final red = PdfColor.fromHex('#DC2626');
    final redL = PdfColor.fromHex('#FEE2E2');
    final amber = PdfColor.fromHex('#D97706');
    final amberL = PdfColor.fromHex('#FEF3C7');

    final fontRegular = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pw.TextStyle ts(double size, PdfColor color, {bool bold = false}) =>
        pw.TextStyle(
          font: bold ? fontBold : fontRegular,
          fontSize: size,
          color: color,
        );

    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final timeStr = _formatTime(now);

    pw.Widget infoCell(String label, String value, PdfColor bg) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 4),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(color: bg),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: ts(8, g500)),
            pw.SizedBox(height: 2),
            pw.Text(
              value.isNotEmpty ? value : 'N/A',
              style: ts(10, g900, bold: true),
            ),
          ],
        ),
      ),
    );

    pw.Widget outcomeBadge(String outcome) {
      final label = outcome == 'pass'
          ? 'PASS'
          : outcome == 'refer'
          ? 'REFER'
          : 'PENDING';
      final color = outcome == 'pass'
          ? green
          : outcome == 'refer'
          ? red
          : amber;
      final bg = outcome == 'pass'
          ? greenL
          : outcome == 'refer'
          ? redL
          : amberL;
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: pw.BoxDecoration(color: bg),
        child: pw.Text(label, style: ts(10, color, bold: true)),
      );
    }

    pw.Widget vaBox(String eye, String? snellen, String? logmar) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(color: g50),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(eye, style: ts(8, g500, bold: true)),
            pw.SizedBox(height: 3),
            pw.Text(
              snellen?.isNotEmpty == true ? snellen! : 'N/A',
              style: ts(13, teal, bold: true),
            ),
            if (logmar?.isNotEmpty == true)
              pw.Text('logMAR: $logmar', style: ts(8, g500)),
          ],
        ),
      ),
    );

    pw.Widget patientCard(Map<String, dynamic> patient) {
      final name = (patient['name'] as String?) ?? 'Unknown';
      final age = (patient['age'] as int?) ?? 0;
      final gender = (patient['gender'] as String?) ?? '';
      final village = (patient['village'] as String?) ?? '';
      final phone = (patient['phone'] as String?) ?? '';
      final patientId = (patient['id'] as String?) ?? '';
      final outcome = (patient['outcome'] as String?) ?? 'pending';
      final odSnellen = (patient['od_snellen'] as String?) ?? '';
      final osSnellen = (patient['os_snellen'] as String?) ?? '';
      final ouNearSnellen = (patient['ou_near_snellen'] as String?) ?? '';
      final odLogmar = (patient['od_logmar'] as String?) ?? '';
      final osLogmar = (patient['os_logmar'] as String?) ?? '';
      final screeningDate = (patient['screening_date'] as String?) ?? '';
      final chwName = ((patient['chw_name'] as String?) ?? '').isNotEmpty
          ? patient['chw_name'] as String
          : profile.displayChwName;
      final facility = (patient['referral_facility'] as String?) ?? '';
      final appointmentDate = (patient['appointment_date'] as String?) ?? '';
      final referralStatus = (patient['referral_status'] as String?) ?? '';
      final conditions = (patient['conditions'] as String?) ?? '';
      final isRefer = outcome == 'refer';
      final accentColor = outcome == 'pass'
          ? green
          : outcome == 'refer'
          ? red
          : amber;
      final cardBg = outcome == 'pass'
          ? greenL
          : outcome == 'refer'
          ? redL
          : amberL;

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: accentColor, width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              color: cardBg,
              padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 4,
                        height: 40,
                        decoration: pw.BoxDecoration(color: accentColor),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(name, style: ts(14, g900, bold: true)),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '$age yrs  |  $gender  |  $village',
                            style: ts(10, g700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      outcomeBadge(outcome),
                      pw.SizedBox(height: 4),
                      pw.Text('ID: $patientId', style: ts(8, g500)),
                    ],
                  ),
                ],
              ),
            ),
            pw.Container(
              color: g50,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: pw.Row(
                children: [
                  infoCell('Phone', phone, g50),
                  infoCell(
                    'Screened',
                    screeningDate.length >= 10
                        ? screeningDate.substring(0, 10)
                        : (screeningDate.isNotEmpty
                              ? screeningDate
                              : 'Not screened'),
                    g50,
                  ),
                  infoCell('CHW', chwName, g50),
                  if (conditions.isNotEmpty)
                    infoCell('Conditions', conditions, g50),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Visual Acuity', style: ts(10, teal, bold: true)),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    children: [
                      vaBox('OD (Right Eye)', odSnellen, odLogmar),
                      pw.SizedBox(width: 6),
                      vaBox('OS (Left Eye)', osSnellen, osLogmar),
                      pw.SizedBox(width: 6),
                      vaBox('OU (Near)', ouNearSnellen, null),
                    ],
                  ),
                ],
              ),
            ),
            if (isRefer)
              pw.Container(
                color: redL,
                padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Referral Details', style: ts(10, red, bold: true)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        infoCell('Referral Facility', facility, redL),
                        infoCell(
                          'Appointment',
                          appointmentDate.length >= 10
                              ? appointmentDate.substring(0, 10)
                              : (appointmentDate.isNotEmpty
                                    ? appointmentDate
                                    : 'Not set'),
                          redL,
                        ),
                        infoCell(
                          'Referral Status',
                          referralStatus.isNotEmpty
                              ? referralStatus.toUpperCase()
                              : 'PENDING',
                          redL,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 28),
        header: (ctx) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VisionScreen Patient Records',
                      style: ts(18, teal, bold: true),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${profile.displayChwName}  |  ${profile.displayCenterOrDistrict}  |  $dateStr  $timeStr',
                      style: ts(10, g700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                      style: ts(10, g500),
                    ),
                    pw.Text(
                      '${patients.length} patients  |  CHW ID: ${profile.displayBadgeId}',
                      style: ts(10, g500),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: teal, thickness: 2),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: g200, thickness: 1),
            pw.SizedBox(height: 3),
            pw.Text(
              'VisionScreen | Community Screening | Generated $dateStr at $timeStr',
              style: ts(8, g500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(color: teal2),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${patients.length}',
                        style: ts(20, teal, bold: true),
                      ),
                      pw.Text('Total Patients', style: ts(9, g700, bold: true)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${patients.where((p) => p['outcome'] == 'pass').length}',
                        style: ts(20, green, bold: true),
                      ),
                      pw.Text('Passed', style: ts(9, g700, bold: true)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${patients.where((p) => p['outcome'] == 'refer').length}',
                        style: ts(20, red, bold: true),
                      ),
                      pw.Text('Referred', style: ts(9, g700, bold: true)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${patients.where((p) => p['outcome'] == null || p['outcome'] == 'pending').length}',
                        style: ts(20, amber, bold: true),
                      ),
                      pw.Text('Pending', style: ts(9, g700, bold: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          ...patients.map((patient) => patientCard(patient)),
        ],
      ),
    );

    return _writePdfFile(pdf, 'visionscreen_patients');
  }

  static Future<File?> exportCampaignRecordsPdf(
    SettingsExportProfile profile,
  ) async {
    final database = await DatabaseHelper.instance.db;
    final campaigns = await database.query(
      'campaigns',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );

    if (campaigns.isEmpty) return null;

    final pdf = pw.Document();
    final teal = PdfColor.fromHex('#0D9488');
    final ink = PdfColor.fromHex('#04091A');
    final g400 = PdfColor.fromHex('#8FA0B4');
    final g800 = PdfColor.fromHex('#1A2A3D');
    final green = PdfColor.fromHex('#22C55E');
    final red = PdfColor.fromHex('#EF4444');
    final amber = PdfColor.fromHex('#F59E0B');
    final g100 = PdfColor.fromHex('#F0F4F7');
    final purple = PdfColor.fromHex('#8B5CF6');
    final white = PdfColors.white;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => pw.Container(
          color: ink,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.fromLTRB(40, 48, 40, 36),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [purple, teal],
                    begin: pw.Alignment.centerLeft,
                    end: pw.Alignment.centerRight,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VisionScreen',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: white,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Campaign Records Export',
                      style: pw.TextStyle(fontSize: 16, color: white),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _pdfInfoRow(
                      'CHW Name',
                      profile.chwName.isNotEmpty ? profile.chwName : '-',
                      g400,
                      white,
                    ),
                    _pdfInfoRow(
                      'Health Center',
                      profile.chwCenter.isNotEmpty ? profile.chwCenter : '-',
                      g400,
                      white,
                    ),
                    _pdfInfoRow(
                      'District',
                      profile.chwDistrict.isNotEmpty
                          ? profile.chwDistrict
                          : '-',
                      g400,
                      white,
                    ),
                    _pdfInfoRow(
                      'Badge ID',
                      profile.chwId.isNotEmpty ? profile.chwId : '-',
                      g400,
                      white,
                    ),
                    _pdfInfoRow(
                      'Export Date',
                      DateTime.now().toString().substring(0, 16),
                      g400,
                      white,
                    ),
                    _pdfInfoRow(
                      'Total Campaigns',
                      '${campaigns.length}',
                      g400,
                      white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    for (final campaign in campaigns) {
      final campaignId = campaign['id'] as String;
      final total = (campaign['total'] as int?) ?? 0;
      final passed = (campaign['passed'] as int?) ?? 0;
      final referred = (campaign['referred'] as int?) ?? 0;
      final passRate = total > 0
          ? (passed / total * 100).toStringAsFixed(1)
          : '0.0';
      final patients = await CampaignRepository.instance.getPatientsForCampaign(
        campaignId,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: purple,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      campaign['name'] as String? ?? '-',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${campaign['location']} - ${campaign['target_group']} - ${campaign['created_at'].toString().substring(0, 10)}',
                      style: pw.TextStyle(fontSize: 11, color: white),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  _pdfStatBox('Total', '$total', teal, white, g100),
                  pw.SizedBox(width: 8),
                  _pdfStatBox('Passed', '$passed', green, white, g100),
                  pw.SizedBox(width: 8),
                  _pdfStatBox('Referred', '$referred', red, white, g100),
                  pw.SizedBox(width: 8),
                  _pdfStatBox('Pass Rate', '$passRate%', amber, white, g100),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Patients',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: teal,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                color: teal,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: pw.Row(
                  children: [
                    _campaignHeaderCell('Name', 3, white),
                    _campaignHeaderCell('Age', 1, white),
                    _campaignHeaderCell('OD', 1, white),
                    _campaignHeaderCell('OS', 1, white),
                    _campaignHeaderCell('Outcome', 2, white),
                  ],
                ),
              ),
              ...patients.asMap().entries.map((entry) {
                final row = entry.value;
                final outcome = (row['outcome'] as String?) ?? 'pending';
                final outcomeColor = outcome == 'pass'
                    ? green
                    : outcome == 'refer'
                    ? red
                    : amber;
                final bg = entry.key.isEven ? g100 : white;
                return pw.Container(
                  color: bg,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: pw.Row(
                    children: [
                      _campaignValueCell(
                        row['name'] as String? ?? '-',
                        3,
                        g800,
                      ),
                      _campaignValueCell('${row['age']}', 1, g800),
                      _campaignValueCell(
                        row['od_snellen'] as String? ?? '-',
                        1,
                        g800,
                      ),
                      _campaignValueCell(
                        row['os_snellen'] as String? ?? '-',
                        1,
                        g800,
                      ),
                      _campaignValueCell(
                        outcome.toUpperCase(),
                        2,
                        outcomeColor,
                        bold: true,
                      ),
                    ],
                  ),
                );
              }),
              pw.Spacer(),
              pw.Divider(color: g400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'VisionScreen | Community Screening',
                    style: pw.TextStyle(fontSize: 9, color: g400),
                  ),
                  pw.Text(
                    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: pw.TextStyle(fontSize: 9, color: g400),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return _writePdfFile(pdf, 'visionscreen_campaigns');
  }

  static Future<File> exportActivityPdf(SettingsExportProfile profile) async {
    final outcomes = await ScreeningRepository.instance.getOutcomeCounts();
    final ageGroups = await ScreeningRepository.instance.getAgeGroupCounts();
    final genders = await ScreeningRepository.instance.getGenderCounts();
    final acuity = await ScreeningRepository.instance
        .getVisualAcuityDistribution();
    final referrals = await ScreeningRepository.instance
        .getReferralStatusCounts();
    final conditions = await ScreeningRepository.instance.getConditionCounts();
    final villages = await ScreeningRepository.instance.getVillageBreakdown();
    final severity = await ScreeningRepository.instance
        .getSeverityClassification();
    final campaigns = await CampaignRepository.instance.getAllCampaigns();
    final condByAge = await ScreeningRepository.instance
        .getConditionsByAgeGroup();

    final passed = outcomes['pass'] ?? 0;
    final referred = outcomes['refer'] ?? 0;
    final pending = outcomes['pending'] ?? 0;
    final screened = passed + referred;
    final total = screened + pending;
    final passRate = screened > 0
        ? (passed / screened * 100).toStringAsFixed(1)
        : '0.0';
    final referRate = screened > 0
        ? (referred / screened * 100).toStringAsFixed(1)
        : '0.0';

    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final timeStr = _formatTime(now);

    final male = genders['M'] ?? 0;
    final female = genders['F'] ?? 0;
    final gTotal = male + female;

    final campTotal = campaigns.fold<int>(
      0,
      (sum, campaign) => sum + ((campaign['total'] as int?) ?? 0),
    );
    final campPassed = campaigns.fold<int>(
      0,
      (sum, campaign) => sum + ((campaign['passed'] as int?) ?? 0),
    );
    final campReferred = campaigns.fold<int>(
      0,
      (sum, campaign) => sum + ((campaign['referred'] as int?) ?? 0),
    );
    final overdue = referrals['overdue'] ?? 0;
    final completed = referrals['completed'] ?? 0;
    final topCond = conditions.isEmpty
        ? null
        : conditions.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topVillage = villages.isEmpty ? null : villages.first;

    final teal = PdfColor.fromHex('#0D9488');
    final teal2 = PdfColor.fromHex('#CCFBF1');
    final g900 = PdfColor.fromHex('#0F172A');
    final g700 = PdfColor.fromHex('#334155');
    final g500 = PdfColor.fromHex('#64748B');
    final g200 = PdfColor.fromHex('#E2E8F0');
    final g50 = PdfColor.fromHex('#F8FAFC');
    final green = PdfColor.fromHex('#16A34A');
    final greenL = PdfColor.fromHex('#DCFCE7');
    final red = PdfColor.fromHex('#DC2626');
    final redL = PdfColor.fromHex('#FEE2E2');
    final amber = PdfColor.fromHex('#D97706');
    final amberL = PdfColor.fromHex('#FEF3C7');
    final blue = PdfColor.fromHex('#2563EB');
    final blueL = PdfColor.fromHex('#DBEAFE');
    final purp = PdfColor.fromHex('#7C3AED');
    final purpL = PdfColor.fromHex('#EDE9FE');
    final white = PdfColors.white;

    final fontRegular = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pw.TextStyle ts(double size, PdfColor color, {bool bold = false}) =>
        pw.TextStyle(
          font: bold ? fontBold : fontRegular,
          fontSize: size,
          color: color,
        );

    pw.Widget secHeader(String title, PdfColor bg) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 18, bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: pw.BoxDecoration(color: bg),
      child: pw.Text(title, style: ts(13, white, bold: true)),
    );

    pw.Widget statCard(
      String label,
      String value,
      PdfColor accent,
      PdfColor bg,
    ) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        decoration: pw.BoxDecoration(color: bg),
        child: pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 52,
              decoration: pw.BoxDecoration(color: accent),
            ),
            pw.SizedBox(width: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(value, style: ts(20, accent, bold: true)),
                pw.Text(label, style: ts(9, g500)),
              ],
            ),
          ],
        ),
      ),
    );

    pw.Widget barRow(
      String label,
      int count,
      int denom,
      PdfColor barColor,
      PdfColor barBg,
    ) {
      final pct = denom > 0 ? (count / denom).clamp(0.0, 1.0) : 0.0;
      const barWidth = 180.0;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(width: 130, child: pw.Text(label, style: ts(10, g700))),
            pw.SizedBox(width: 8),
            pw.Stack(
              children: [
                pw.Container(
                  width: barWidth,
                  height: 14,
                  decoration: pw.BoxDecoration(color: barBg),
                ),
                pw.Container(
                  width: (pct * barWidth).clamp(2.0, barWidth),
                  height: 14,
                  decoration: pw.BoxDecoration(color: barColor),
                ),
              ],
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '$count  (${(pct * 100).toStringAsFixed(0)}%)',
              style: ts(10, g900, bold: true),
            ),
          ],
        ),
      );
    }

    pw.Widget tableHeader(List<(String, int)> cols, PdfColor bg) =>
        pw.Container(
          color: bg,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Row(
            children: cols
                .map(
                  (col) => pw.Expanded(
                    flex: col.$2,
                    child: pw.Text(col.$1, style: ts(10, white, bold: true)),
                  ),
                )
                .toList(),
          ),
        );

    pw.Widget tableRow(List<(String, int, PdfColor)> cells, PdfColor bg) =>
        pw.Container(
          color: bg,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            children: cells
                .map(
                  (cell) => pw.Expanded(
                    flex: cell.$2,
                    child: pw.Text(cell.$1, style: ts(10, cell.$3)),
                  ),
                )
                .toList(),
          ),
        );

    pw.Widget summaryRow(
      String label,
      String text,
      PdfColor accent,
      PdfColor bg,
    ) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(color: bg),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 4, decoration: pw.BoxDecoration(color: accent)),
          pw.SizedBox(width: 8),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: pw.BoxDecoration(color: accent),
              child: pw.Text(label, style: ts(8, white, bold: true)),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(text, style: ts(10, g700)),
            ),
          ),
        ],
      ),
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 32),
        header: (ctx) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VisionScreen Activity Report',
                      style: ts(18, teal, bold: true),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${profile.displayChwName}   |   ${profile.displayCenterOrDistrict}   |   $dateStr  $timeStr',
                      style: ts(10, g500),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                      style: ts(9, g500),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'CHW ID: ${profile.displayBadgeId}',
                      style: ts(9, g500),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: teal, thickness: 2),
          ],
        ),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: g200, thickness: 1),
            pw.SizedBox(height: 4),
            pw.Text(
              'VisionScreen | Community Screening | Generated $dateStr at $timeStr',
              style: ts(8, g500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
        build: (ctx) => [
          secHeader('1.  Screening Summary', teal),
          pw.Row(
            children: [
              statCard('Total Patients', '$total', g900, g50),
              statCard('Screened', '$screened', teal, teal2),
              statCard('Passed', '$passed', green, greenL),
              statCard('Referred', '$referred', red, redL),
              statCard('Pending', '$pending', amber, amberL),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              statCard('Pass Rate', '$passRate%', green, greenL),
              statCard('Referral Rate', '$referRate%', red, redL),
              statCard('Campaigns', '${campaigns.length}', purp, purpL),
              statCard('Camp. Screened', '$campTotal', teal, teal2),
              statCard(
                'Overdue Refs',
                '$overdue',
                overdue > 0 ? red : g500,
                overdue > 0 ? redL : g50,
              ),
            ],
          ),
          secHeader('2.  Demographics', blue),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Age Groups', style: ts(11, g900, bold: true)),
                    pw.SizedBox(height: 8),
                    barRow(
                      '0 - 17  (Children)',
                      ageGroups['0-17'] ?? 0,
                      total,
                      blue,
                      blueL,
                    ),
                    barRow(
                      '18 - 40  (Youth)',
                      ageGroups['18-40'] ?? 0,
                      total,
                      teal,
                      teal2,
                    ),
                    barRow(
                      '41 - 60  (Adults)',
                      ageGroups['41-60'] ?? 0,
                      total,
                      amber,
                      amberL,
                    ),
                    barRow(
                      '60+  (Elderly)',
                      ageGroups['60+'] ?? 0,
                      total,
                      red,
                      redL,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Gender', style: ts(11, g900, bold: true)),
                    pw.SizedBox(height: 8),
                    barRow('Male', male, gTotal > 0 ? gTotal : 1, blue, blueL),
                    barRow(
                      'Female',
                      female,
                      gTotal > 0 ? gTotal : 1,
                      PdfColor.fromHex('#DB2777'),
                      PdfColor.fromHex('#FCE7F3'),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Total: $gTotal patients', style: ts(9, g500)),
                  ],
                ),
              ),
            ],
          ),
          secHeader('3.  Visual Acuity Distribution', teal),
          pw.Text(
            'Based on worst-eye Snellen result per patient.',
            style: ts(10, g500),
          ),
          pw.SizedBox(height: 8),
          barRow(
            'Normal  (6/6)',
            acuity['Normal'] ?? 0,
            screened > 0 ? screened : 1,
            green,
            greenL,
          ),
          barRow(
            'Near Normal  (6/9 - 6/12)',
            acuity['Near Normal'] ?? 0,
            screened > 0 ? screened : 1,
            teal,
            teal2,
          ),
          barRow(
            'Moderate  (6/18 - 6/24)',
            acuity['Moderate'] ?? 0,
            screened > 0 ? screened : 1,
            amber,
            amberL,
          ),
          barRow(
            'Severe  (6/36 - 6/60)',
            acuity['Severe'] ?? 0,
            screened > 0 ? screened : 1,
            red,
            redL,
          ),
          barRow(
            'Blind Range  (<6/60)',
            acuity['Blind Range'] ?? 0,
            screened > 0 ? screened : 1,
            purp,
            purpL,
          ),
          secHeader('4.  Severity Classification', amber),
          pw.Text(
            'Derived from worst-eye logMAR per patient.',
            style: ts(10, g500),
          ),
          pw.SizedBox(height: 8),
          barRow(
            'Normal',
            severity['Normal'] ?? 0,
            screened > 0 ? screened : 1,
            green,
            greenL,
          ),
          barRow(
            'Mild',
            severity['Mild'] ?? 0,
            screened > 0 ? screened : 1,
            teal,
            teal2,
          ),
          barRow(
            'Moderate',
            severity['Moderate'] ?? 0,
            screened > 0 ? screened : 1,
            amber,
            amberL,
          ),
          barRow(
            'Severe',
            severity['Severe'] ?? 0,
            screened > 0 ? screened : 1,
            red,
            redL,
          ),
          barRow(
            'Critical',
            severity['Critical'] ?? 0,
            screened > 0 ? screened : 1,
            purp,
            purpL,
          ),
          if (conditions.isNotEmpty) ...[
            secHeader('5.  Eye Conditions Reported', purp),
            pw.Text(
              'CHW-observed symptoms - top ${conditions.length > 8 ? 8 : conditions.length} conditions.',
              style: ts(10, g500),
            ),
            pw.SizedBox(height: 8),
            ...(conditions.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .take(8)
                .map(
                  (entry) => barRow(
                    entry.key,
                    entry.value,
                    total > 0 ? total : 1,
                    purp,
                    purpL,
                  ),
                ),
          ],
          secHeader('6.  Referral Status Breakdown', red),
          pw.Text('Total referred: $referred patients.', style: ts(10, g500)),
          pw.SizedBox(height: 8),
          barRow(
            'Pending',
            referrals['pending'] ?? 0,
            referred > 0 ? referred : 1,
            amber,
            amberL,
          ),
          barRow(
            'Notified',
            referrals['notified'] ?? 0,
            referred > 0 ? referred : 1,
            blue,
            blueL,
          ),
          barRow(
            'Attended',
            referrals['attended'] ?? 0,
            referred > 0 ? referred : 1,
            teal,
            teal2,
          ),
          barRow(
            'Completed',
            referrals['completed'] ?? 0,
            referred > 0 ? referred : 1,
            green,
            greenL,
          ),
          barRow(
            'Overdue',
            referrals['overdue'] ?? 0,
            referred > 0 ? referred : 1,
            red,
            redL,
          ),
          barRow(
            'Cancelled',
            referrals['cancelled'] ?? 0,
            referred > 0 ? referred : 1,
            g500,
            g50,
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text('Completion rate: ', style: ts(10, g500)),
              pw.Text(
                referred > 0
                    ? '${(completed / referred * 100).toStringAsFixed(0)}%'
                    : '0%',
                style: ts(10, green, bold: true),
              ),
              pw.SizedBox(width: 20),
              pw.Text('Overdue rate: ', style: ts(10, g500)),
              pw.Text(
                referred > 0
                    ? '${(overdue / referred * 100).toStringAsFixed(0)}%'
                    : '0%',
                style: ts(10, overdue > 0 ? red : g500, bold: true),
              ),
            ],
          ),
          if (villages.isNotEmpty) ...[
            secHeader('7.  Village / Location Breakdown', teal),
            tableHeader([
              ('No.', 1),
              ('Village', 4),
              ('Total', 2),
              ('Referred', 2),
              ('Pass Rate', 2),
            ], teal),
            ...villages.asMap().entries.map((entry) {
              final village = entry.value;
              final totalCount = (village['total'] as int?) ?? 0;
              final referredCount = (village['referred'] as int?) ?? 0;
              final passedCount = totalCount - referredCount;
              final passRateLabel = totalCount > 0
                  ? '${(passedCount / totalCount * 100).toStringAsFixed(0)}%'
                  : '-';
              return tableRow([
                ('${entry.key + 1}', 1, g500),
                (village['village'] as String, 4, g900),
                ('$totalCount', 2, g900),
                ('$referredCount', 2, referredCount > 0 ? red : g500),
                (passRateLabel, 2, teal),
              ], entry.key.isEven ? g50 : white);
            }),
          ],
          if (campaigns.isNotEmpty) ...[
            secHeader('8.  Campaign Outcomes', purp),
            tableHeader([
              ('Campaign', 4),
              ('Screened', 2),
              ('Passed', 2),
              ('Referred', 2),
              ('Pass Rate', 2),
            ], purp),
            ...campaigns.asMap().entries.map((entry) {
              final campaign = entry.value;
              final totalCount = (campaign['total'] as int?) ?? 0;
              final passedCount = (campaign['passed'] as int?) ?? 0;
              final referredCount = (campaign['referred'] as int?) ?? 0;
              final campaignRate = totalCount > 0
                  ? '${(passedCount / totalCount * 100).toStringAsFixed(0)}%'
                  : '-';
              return tableRow([
                (campaign['name'] as String, 4, g900),
                ('$totalCount', 2, g900),
                ('$passedCount', 2, green),
                ('$referredCount', 2, referredCount > 0 ? red : g500),
                (campaignRate, 2, teal),
              ], entry.key.isEven ? g50 : white);
            }),
            pw.SizedBox(height: 6),
            pw.Text(
              'Combined totals - Screened: $campTotal   |   Passed: $campPassed   |   Referred: $campReferred',
              style: ts(9, g500),
            ),
          ],
          if (condByAge.isNotEmpty) ...[
            secHeader('9.  Conditions by Age Group', blue),
            tableHeader([
              ('Condition', 4),
              ('0-17', 2),
              ('18-60', 2),
              ('60+', 2),
              ('Total', 2),
            ], blue),
            ...(condByAge.entries.toList()..sort((a, b) {
                  final totalA = a.value.values.fold(
                    0,
                    (sum, value) => sum + value,
                  );
                  final totalB = b.value.values.fold(
                    0,
                    (sum, value) => sum + value,
                  );
                  return totalB.compareTo(totalA);
                }))
                .take(10)
                .toList()
                .asMap()
                .entries
                .map((entry) {
                  final conditionName = entry.value.key;
                  final conditionValues = entry.value.value;
                  final group0 = conditionValues['0-17'] ?? 0;
                  final group1 = conditionValues['18-60'] ?? 0;
                  final group2 = conditionValues['60+'] ?? 0;
                  return tableRow([
                    (conditionName, 4, g900),
                    ('$group0', 2, blue),
                    ('$group1', 2, teal),
                    ('$group2', 2, red),
                    ('${group0 + group1 + group2}', 2, g900),
                  ], entry.key.isEven ? g50 : white);
                }),
          ],
          secHeader('10.  Summary', g900),
          pw.SizedBox(height: 4),
          if (screened == 0)
            summaryRow(
              'DATA',
              'No screening data is available for this export period.',
              g500,
              g50,
            )
          else ...[
            summaryRow(
              'OUTCOME',
              'Pass rate: $passRate% across $screened completed screening${screened == 1 ? '' : 's'}.',
              teal,
              teal2,
            ),
            if (overdue > 0)
              summaryRow(
                'FOLLOW-UP',
                '$overdue referral${overdue == 1 ? '' : 's'} currently overdue.',
                red,
                redL,
              ),
            if (topCond != null)
              summaryRow(
                'CONDITION',
                'Most recorded condition: ${topCond.key} (${topCond.value} case${topCond.value == 1 ? '' : 's'}).',
                blue,
                blueL,
              ),
            if (topVillage != null)
              summaryRow(
                'LOCATION',
                'Highest screening volume: ${topVillage['village']} (${topVillage['total']} patient${topVillage['total'] == 1 ? '' : 's'}).',
                purp,
                purpL,
              ),
            if (referred > 0)
              summaryRow(
                'REFERRALS',
                'Completed referrals: $completed of $referred (${(completed / referred * 100).toStringAsFixed(0)}%).',
                green,
                greenL,
              ),
          ],
          pw.SizedBox(height: 16),
        ],
      ),
    );

    return _writePdfFile(pdf, 'visionscreen_activity');
  }

  static pw.Widget _pdfStatBox(
    String label,
    String value,
    PdfColor color,
    PdfColor white,
    PdfColor bg,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pdfInfoRow(
    String label,
    String value,
    PdfColor labelColor,
    PdfColor valueColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, color: labelColor),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _campaignHeaderCell(String text, int flex, PdfColor color) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _campaignValueCell(
    String text,
    int flex,
    PdfColor color, {
    bool bold = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static Future<File> _writePdfFile(pw.Document pdf, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${prefix}_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
