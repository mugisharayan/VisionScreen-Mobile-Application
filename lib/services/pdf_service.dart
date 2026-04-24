import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  PdfService._();

  // Build the referral PDF document
  static Future<pw.Document> _buildReferralDoc({
    required Map<String, String> patient,
    required List<Map<String, dynamic>> eyeResults,
    required String screeningDate,
    required String facility,
    required String chwName,
    required String chwTitle,
    required String? appointmentDate,
    required List<String> conditions,
  }) async {
    final font     = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final chw = chwName.isEmpty ? '[CHW Name]' : chwName;

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF04091A)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                  pw.Text('REFERRAL LETTER',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 15,
                          color: PdfColors.white)),
                  pw.Text('Vision Screening Programme',
                      style: pw.TextStyle(
                          font: font, fontSize: 9, color: PdfColors.white)),
                ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                  pw.Text('Date: $screeningDate',
                      style: pw.TextStyle(
                          font: font, fontSize: 9, color: PdfColors.white)),
                  if (appointmentDate != null && appointmentDate.isNotEmpty)
                    pw.Text('Appt: $appointmentDate',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            color: PdfColors.white)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(children: [
            pw.Expanded(
                child: _box('TO', 'The Eye Specialist\n$facility', font,
                    fontBold)),
            pw.SizedBox(width: 10),
            pw.Expanded(
                child: _box('FROM', '$chw\n$chwTitle', font, fontBold)),
          ]),
          pw.SizedBox(height: 14),
          pw.Text('PATIENT DETAILS',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFB),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFEEF2F6))),
            child: pw.Column(children: [
              _kv('Name', patient['name'] ?? '', font, fontBold),
              _kv('Patient ID', patient['id'] ?? '', font, fontBold),
              _kv('Age / Sex',
                  '${patient['age']} yrs  ${patient['gender'] == 'M' ? 'Male' : 'Female'}',
                  font, fontBold),
              _kv('Village', patient['village'] ?? '', font, fontBold),
              if ((patient['phone'] ?? '').isNotEmpty)
                _kv('Phone', patient['phone']!, font, fontBold),
              if (conditions.isNotEmpty)
                _kv('Conditions', conditions.join(', '), font, fontBold),
              if (appointmentDate != null && appointmentDate.isNotEmpty)
                _kv('Appointment', appointmentDate, font, fontBold),
            ]),
          ),
          pw.SizedBox(height: 14),
          pw.Text('VISUAL ACUITY RESULTS',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text('Distance Vision (Monocular - Tumbling E)',
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.SizedBox(height: 6),
          if (eyeResults.isEmpty)
            pw.Text('No visual acuity data recorded.',
                style: pw.TextStyle(font: font, fontSize: 10))
          else
            ...eyeResults.map((r) => _vaRow(r, font, fontBold)),
          pw.SizedBox(height: 14),
          pw.Text('REASON FOR REFERRAL',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFEF4444))),
            child: pw.Text(
              'Visual acuity below 6/12 detected in one or more eyes during '
              'community vision screening. Further examination and management '
              'is recommended.',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('________________________________',
              style: pw.TextStyle(font: font, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(chw,
              style: pw.TextStyle(font: fontBold, fontSize: 11)),
          pw.Text(chwTitle,
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text('Date: $screeningDate',
              style: pw.TextStyle(font: font, fontSize: 9)),
        ],
      ),
    ));
    return doc;
  }

  // Build the pass result PDF document
  static Future<pw.Document> _buildPassDoc({
    required Map<String, String> patient,
    required List<Map<String, dynamic>> eyeResults,
    required String screeningDate,
    required String chwName,
    required String chwTitle,
    required List<String> conditions,
  }) async {
    final font     = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final chw = chwName.isEmpty ? '[CHW Name]' : chwName;

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF04091A)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                  pw.Text('VISION SCREENING RESULT',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 15,
                          color: PdfColors.white)),
                  pw.Text('Community Eye Health Programme',
                      style: pw.TextStyle(
                          font: font, fontSize: 9, color: PdfColors.white)),
                ]),
                pw.Text('Date: $screeningDate',
                    style: pw.TextStyle(
                        font: font, fontSize: 9, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          // Pass badge
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFF22C55E), width: 2)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('VISION PASS',
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 20,
                      color: const PdfColor.fromInt(0xFF22C55E))),
              pw.SizedBox(height: 4),
              pw.Text('Vision is within normal range',
                  style: pw.TextStyle(font: font, fontSize: 11)),
            ]),
          ),
          pw.SizedBox(height: 14),
          pw.Text('PATIENT DETAILS',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFB),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFEEF2F6))),
            child: pw.Column(children: [
              _kv('Name', patient['name'] ?? '', font, fontBold),
              _kv('Patient ID', patient['id'] ?? '', font, fontBold),
              _kv('Age / Sex',
                  '${patient['age']} yrs  ${patient['gender'] == 'M' ? 'Male' : 'Female'}',
                  font, fontBold),
              _kv('Village', patient['village'] ?? '', font, fontBold),
              if ((patient['phone'] ?? '').isNotEmpty)
                _kv('Phone', patient['phone']!, font, fontBold),
              if (conditions.isNotEmpty)
                _kv('Conditions', conditions.join(', '), font, fontBold),
            ]),
          ),
          pw.SizedBox(height: 14),
          pw.Text('VISUAL ACUITY RESULTS',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text('Distance Vision (Monocular - Tumbling E)',
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.SizedBox(height: 6),
          if (eyeResults.isEmpty)
            pw.Text('No visual acuity data recorded.',
                style: pw.TextStyle(font: font, fontSize: 10))
          else
            ...eyeResults.map((r) => _vaRowGreen(r, font, fontBold)),
          pw.SizedBox(height: 14),
          pw.Text('RECOMMENDATION',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFF22C55E))),
            child: pw.Text(
              'No referral required at this time. Vision is within acceptable '
              'range. Recommend re-screening in 12 months or sooner if any '
              'visual complaints arise.',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('________________________________',
              style: pw.TextStyle(font: font, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(chw,
              style: pw.TextStyle(font: fontBold, fontSize: 11)),
          pw.Text(chwTitle,
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text('Date: $screeningDate',
              style: pw.TextStyle(font: font, fontSize: 9)),
        ],
      ),
    ));
    return doc;
  }

  // ── Public API ───────────────────────────────────────────────────────────

  static Future<String> generateReferralPdf({
    required Map<String, String> patient,
    required List<Map<String, dynamic>> eyeResults,
    required String screeningDate,
    required String facility,
    required String chwName,
    required String chwTitle,
    required String? appointmentDate,
    required List<String> conditions,
  }) async {
    final doc = await _buildReferralDoc(
      patient: patient, eyeResults: eyeResults,
      screeningDate: screeningDate, facility: facility,
      chwName: chwName, chwTitle: chwTitle,
      appointmentDate: appointmentDate, conditions: conditions,
    );
    return _save(doc,
        'Referral_${(patient['name'] ?? 'patient').replaceAll(' ', '_')}_$screeningDate.pdf');
  }

  static Future<String> generatePassResultPdf({
    required Map<String, String> patient,
    required List<Map<String, dynamic>> eyeResults,
    required String screeningDate,
    required String chwName,
    required String chwTitle,
    required List<String> conditions,
  }) async {
    final doc = await _buildPassDoc(
      patient: patient, eyeResults: eyeResults,
      screeningDate: screeningDate,
      chwName: chwName, chwTitle: chwTitle,
      conditions: conditions,
    );
    return _save(doc,
        'Result_${(patient['name'] ?? 'patient').replaceAll(' ', '_')}_$screeningDate.pdf');
  }

  static Future<void> openOrShare(
      BuildContext context, String path, String subject) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      await Share.shareXFiles([XFile(path)], subject: subject);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Future<String> _save(pw.Document doc, String filename) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  static String _toSnellen(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return logmar;
    const snaps = [6, 9, 12, 18, 24, 36, 48, 60, 120];
    double r = 1.0;
    final steps = (v.abs() * 10).round();
    for (int i = 0; i < steps; i++) r *= (v >= 0 ? 1.258925 : 0.794328);
    final second = (6 * r).round();
    return '6/${snaps.reduce((a, b) => (a - second).abs() < (b - second).abs() ? a : b)}';
  }

  static String _vaClass(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return '';
    if (v <= 0.0) return 'Normal';
    if (v <= 0.3) return 'Near Normal';
    if (v <= 0.5) return 'Moderate Impairment';
    if (v <= 1.0) return 'Severe Impairment';
    return 'Blind Range';
  }

  static PdfColor _vaColor(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return const PdfColor.fromInt(0xFFEF4444);
    if (v <= 0.3) return const PdfColor.fromInt(0xFF22C55E);
    if (v <= 0.5) return const PdfColor.fromInt(0xFFF59E0B);
    return const PdfColor.fromInt(0xFFEF4444);
  }

  static pw.Widget _box(
      String label, String value, pw.Font font, pw.Font bold) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF8FAFB),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFEEF2F6))),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.Text(label,
              style: pw.TextStyle(font: bold, fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
        ]),
      );

  static pw.Widget _kv(
      String label, String value, pw.Font font, pw.Font bold) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
          pw.SizedBox(
              width: 90,
              child: pw.Text(label,
                  style: pw.TextStyle(font: font, fontSize: 10))),
          pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(font: bold, fontSize: 10))),
        ]),
      );

  static pw.Widget _vaRow(
      Map<String, dynamic> r, pw.Font font, pw.Font bold) {
    final eye    = r['eye'] as String;
    final logmar = r['logmar'] as String;
    final col    = _vaColor(logmar);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: col)),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(eye == 'OD' ? 'Right Eye (OD)' : 'Left Eye (OS)',
              style: pw.TextStyle(font: bold, fontSize: 11)),
          pw.Text(_vaClass(logmar),
              style: pw.TextStyle(font: font, fontSize: 9)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(_toSnellen(logmar),
              style: pw.TextStyle(font: bold, fontSize: 16, color: col)),
          pw.Text('LogMAR $logmar',
              style: pw.TextStyle(font: font, fontSize: 9)),
        ]),
      ]),
    );
  }

  static pw.Widget _vaRowGreen(
      Map<String, dynamic> r, pw.Font font, pw.Font bold) {
    final eye    = r['eye'] as String;
    final logmar = r['logmar'] as String;
    const col    = PdfColor.fromInt(0xFF22C55E);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: col)),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(eye == 'OD' ? 'Right Eye (OD)' : 'Left Eye (OS)',
              style: pw.TextStyle(font: bold, fontSize: 11)),
          pw.Text(_vaClass(logmar),
              style: pw.TextStyle(font: font, fontSize: 9)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(_toSnellen(logmar),
              style: pw.TextStyle(font: bold, fontSize: 16, color: col)),
          pw.Text('LogMAR $logmar',
              style: pw.TextStyle(font: font, fontSize: 9)),
        ]),
      ]),
    );
  }
}
