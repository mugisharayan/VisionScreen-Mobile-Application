import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

const _pdfTranslations = <String, Map<String, String>>{
  'Luganda': {
    'referral_letter': 'EBBALUWA EYA OKUKEBERA AMAASO / REFERRAL LETTER',
    'vision_screening': 'Pulogulaamu ya Okukebera Amaaso / Vision Screening Programme',
    'to': 'Eri / TO',
    'from': 'Okuva / FROM',
    'eye_specialist': 'Omusawo wa Maaso / The Eye Specialist',
    'patient_details': 'EBIMU KU MULWADDE / PATIENT DETAILS',
    'name': 'Erinnya / Name',
    'patient_id': 'Namba ya Mulwadde / Patient ID',
    'age_sex': 'Emyaka / Ekkono / Age / Sex',
    'village': 'Kyalo / Village',
    'conditions': 'Endwadde / Conditions',
    'appointment': 'Olunaku lw\'okujja / Appointment',
    'va_results': 'EBIPIMO BY\'OKULABA / VISUAL ACUITY RESULTS',
    'distance_vision': 'Okulaba Wala (Monocular) / Distance Vision',
    'right_eye': 'Jjelo Ddyo (OD) / Right Eye',
    'left_eye': 'Jjelo Kkono (OS) / Left Eye',
    'reason': 'ENSONGA Y\'OKUKEBERA / REASON FOR REFERRAL',
    'reason_body': 'Okulaba okw\'omulwadde kuli wansi wa 6/12. Okukebera nate n\'okulabirirwa bikwatagana. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Musajja / Male',
    'female': 'Mukazi / Female',
    'badge_id': 'Namba ya Mulimu / Badge ID',
    'date': 'Olunaku / Date',
    'appt': 'Olunaku lw\'okujja / Appt',
  },
  'Runyankole/Rukiga': {
    'referral_letter': 'EBBARUWA Y\'OKWEGYEREKA / REFERRAL LETTER',
    'vision_screening': 'Pulogulaamu y\'Okwegyereka Amaisho / Vision Screening Programme',
    'to': 'Kuri / TO',
    'from': 'Kuva / FROM',
    'eye_specialist': 'Omushaija w\'Amaisho / The Eye Specialist',
    'patient_details': 'AMAKURU G\'OMURWAIRE / PATIENT DETAILS',
    'name': 'Eizina / Name',
    'patient_id': 'Namba y\'Omurwaire / Patient ID',
    'age_sex': 'Emyaka / Orugendo / Age / Sex',
    'village': 'Kyaro / Village',
    'conditions': 'Endwara / Conditions',
    'appointment': 'Eizooba ry\'okuza / Appointment',
    'va_results': 'EBIPIMO BY\'AMAISHO / VISUAL ACUITY RESULTS',
    'distance_vision': 'Kurora Kure (Monocular) / Distance Vision',
    'right_eye': 'Iisho Ry\'Ekuruumi (OD) / Right Eye',
    'left_eye': 'Iisho Ry\'Eibumba (OS) / Left Eye',
    'reason': 'EMPANDURA Y\'OKWEGYEREKA / REASON FOR REFERRAL',
    'reason_body': 'Kurora kw\'omurwaire kuri hasi ya 6/12. Okwegyereka nate n\'okulabirirwa bikweterana. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Omushaija / Male',
    'female': 'Omukazi / Female',
    'badge_id': 'Namba ya Mulimu / Badge ID',
    'date': 'Eizooba / Date',
    'appt': 'Eizooba ry\'okuza / Appt',
  },
  'Acholi': {
    'referral_letter': 'WARAGA ME CWINYA / REFERRAL LETTER',
    'vision_screening': 'Purogram me Nen Wan / Vision Screening Programme',
    'to': 'Bot / TO',
    'from': 'Ki / FROM',
    'eye_specialist': 'Lakwena me Wan / The Eye Specialist',
    'patient_details': 'NGEC PA LACEN / PATIENT DETAILS',
    'name': 'Nying / Name',
    'patient_id': 'Namba pa Lacen / Patient ID',
    'age_sex': 'Mwaka / Dano / Age / Sex',
    'village': 'Gang / Village',
    'conditions': 'Two / Conditions',
    'appointment': 'Nino me Bino / Appointment',
    'va_results': 'KITE ME NEN WAN / VISUAL ACUITY RESULTS',
    'distance_vision': 'Neno Mabor (Monocular) / Distance Vision',
    'right_eye': 'Wan Acuc (OD) / Right Eye',
    'left_eye': 'Wan Acam (OS) / Left Eye',
    'reason': 'POKO ME CWINYA / REASON FOR REFERRAL',
    'reason_body': 'Neno pa lacen tye piny 6/12. Neno odoco ki jami me tic mite. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Laco / Male',
    'female': 'Dako / Female',
    'badge_id': 'Namba me Tic / Badge ID',
    'date': 'Nino / Date',
    'appt': 'Nino me Bino / Appt',
  },
  'Ateso': {
    'referral_letter': 'AKWAP KA ILOSIT / REFERRAL LETTER',
    'vision_screening': 'Aprogramu ka Ilosit Aimaran / Vision Screening Programme',
    'to': 'Kos / TO',
    'from': 'Ijo / FROM',
    'eye_specialist': 'Adokon ka Aimaran / The Eye Specialist',
    'patient_details': 'AKWAP KA AIPEAN / PATIENT DETAILS',
    'name': 'Aran / Name',
    'patient_id': 'Namba ka Aipean / Patient ID',
    'age_sex': 'Iboit / Itunga / Age / Sex',
    'village': 'Ekitela / Village',
    'conditions': 'Aipean / Conditions',
    'appointment': 'Akwap ka Ilosit / Appointment',
    'va_results': 'ILOSIT KA AIMARAN / VISUAL ACUITY RESULTS',
    'distance_vision': 'Ilosit Abwor (Monocular) / Distance Vision',
    'right_eye': 'Aimaran Akuret (OD) / Right Eye',
    'left_eye': 'Aimaran Abwor (OS) / Left Eye',
    'reason': 'AKWAP KA ILOSIT / REASON FOR REFERRAL',
    'reason_body': 'Ilosit ka aipean tun piny 6/12. Ilosit noi ki aprogramu mite. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Ekimat / Male',
    'female': 'Ekimat / Female',
    'badge_id': 'Namba ka Tic / Badge ID',
    'date': 'Akwap / Date',
    'appt': 'Akwap ka Ilosit / Appt',
  },
  'Lugbara': {
    'referral_letter': 'WARAGA RI OKURU / REFERRAL LETTER',
    'vision_screening': 'Pulogulaamu ri Oku Azi / Vision Screening Programme',
    'to': 'Kua / TO',
    'from': 'Ri / FROM',
    'eye_specialist': 'Onzi ri Azi / The Eye Specialist',
    'patient_details': 'AMAKURU RI ONZI / PATIENT DETAILS',
    'name': 'Iri / Name',
    'patient_id': 'Namba ri Onzi / Patient ID',
    'age_sex': 'Ovu / Oku / Age / Sex',
    'village': 'Oku / Village',
    'conditions': 'Adria / Conditions',
    'appointment': 'Oku ri Oku / Appointment',
    'va_results': 'OKU AZI / VISUAL ACUITY RESULTS',
    'distance_vision': 'Oku Azi Kua (Monocular) / Distance Vision',
    'right_eye': 'Azi Ri Kua (OD) / Right Eye',
    'left_eye': 'Azi Ri Oku (OS) / Left Eye',
    'reason': 'ENSONGA RI OKURU / REASON FOR REFERRAL',
    'reason_body': 'Oku azi ri onzi kua piny 6/12. Oku nate ki okulabirirwa bikweterana. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Oku / Male',
    'female': 'Oku / Female',
    'badge_id': 'Namba ri Tic / Badge ID',
    'date': 'Oku / Date',
    'appt': 'Oku ri Oku / Appt',
  },
  'Luo': {
    'referral_letter': 'WARAGA MAR REFERRAL / REFERRAL LETTER',
    'vision_screening': 'Purogram mar Neno / Vision Screening Programme',
    'to': 'Ir / TO',
    'from': 'Oa / FROM',
    'eye_specialist': 'Lakwena mar Wang / The Eye Specialist',
    'patient_details': 'WECHE MAR JATUO / PATIENT DETAILS',
    'name': 'Nying / Name',
    'patient_id': 'Namba mar Jatuo / Patient ID',
    'age_sex': 'Higni / Dichuo / Age / Sex',
    'village': 'Gweng / Village',
    'conditions': 'Tuo / Conditions',
    'appointment': 'Chieng mar Biro / Appointment',
    'va_results': 'KITE MAR NENO / VISUAL ACUITY RESULTS',
    'distance_vision': 'Neno Mabor (Monocular) / Distance Vision',
    'right_eye': 'Wang Korachwich (OD) / Right Eye',
    'left_eye': 'Wang Korachiel (OS) / Left Eye',
    'reason': 'POKO MAR REFERRAL / REASON FOR REFERRAL',
    'reason_body': 'Neno mar jatuo ni piny 6/12. Neno odoco ki tich mite. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Dichuo / Male',
    'female': 'Dhako / Female',
    'badge_id': 'Namba mar Tich / Badge ID',
    'date': 'Chieng / Date',
    'appt': 'Chieng mar Biro / Appt',
  },
  'Runyoro': {
    'referral_letter': 'EBBARUWA Y\'OKWEGYEREKA / REFERRAL LETTER',
    'vision_screening': 'Pulogulaamu y\'Okwegyereka Amaisho / Vision Screening Programme',
    'to': 'Kuri / TO',
    'from': 'Kuva / FROM',
    'eye_specialist': 'Omusawo w\'Amaisho / The Eye Specialist',
    'patient_details': 'AMAKURU G\'OMURWAIRE / PATIENT DETAILS',
    'name': 'Eizina / Name',
    'patient_id': 'Namba y\'Omurwaire / Patient ID',
    'age_sex': 'Emyaka / Orugendo / Age / Sex',
    'village': 'Kyaro / Village',
    'conditions': 'Endwara / Conditions',
    'appointment': 'Eizooba ry\'okuza / Appointment',
    'va_results': 'EBIPIMO BY\'AMAISHO / VISUAL ACUITY RESULTS',
    'distance_vision': 'Kurora Kure (Monocular) / Distance Vision',
    'right_eye': 'Iisho Ry\'Ekuruumi (OD) / Right Eye',
    'left_eye': 'Iisho Ry\'Eibumba (OS) / Left Eye',
    'reason': 'EMPANDURA Y\'OKWEGYEREKA / REASON FOR REFERRAL',
    'reason_body': 'Kurora kw\'omurwaire kuri hasi ya 6/12. Okwegyereka nate n\'okulabirirwa bikweterana. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Omushaija / Male',
    'female': 'Omukazi / Female',
    'badge_id': 'Namba ya Mulimu / Badge ID',
    'date': 'Eizooba / Date',
    'appt': 'Eizooba ry\'okuza / Appt',
  },
  'Swahili': {
    'referral_letter': 'BARUA YA RUFAA / REFERRAL LETTER',
    'vision_screening': 'Mpango wa Uchunguzi wa Macho / Vision Screening Programme',
    'to': 'Kwa / TO',
    'from': 'Kutoka / FROM',
    'eye_specialist': 'Daktari wa Macho / The Eye Specialist',
    'patient_details': 'MAELEZO YA MGONJWA / PATIENT DETAILS',
    'name': 'Jina / Name',
    'patient_id': 'Nambari ya Mgonjwa / Patient ID',
    'age_sex': 'Umri / Jinsia / Age / Sex',
    'village': 'Kijiji / Village',
    'conditions': 'Magonjwa / Conditions',
    'appointment': 'Tarehe ya Miadi / Appointment',
    'va_results': 'MATOKEO YA UONI / VISUAL ACUITY RESULTS',
    'distance_vision': 'Uoni wa Mbali (Monocular) / Distance Vision',
    'right_eye': 'Jicho la Kulia (OD) / Right Eye',
    'left_eye': 'Jicho la Kushoto (OS) / Left Eye',
    'reason': 'SABABU YA RUFAA / REASON FOR REFERRAL',
    'reason_body': 'Uoni wa mgonjwa uko chini ya 6/12. Uchunguzi zaidi unapendekezwa. / Visual acuity below 6/12 detected. Further examination recommended.',
    'male': 'Mwanaume / Male',
    'female': 'Mwanamke / Female',
    'badge_id': 'Nambari ya Kitambulisho / Badge ID',
    'date': 'Tarehe / Date',
    'appt': 'Tarehe ya Miadi / Appt',
  },
};

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
    required String chwId,
    required String? appointmentDate,
    required List<String> conditions,
    required String language,
  }) async {
    final font     = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final chw = chwName.isEmpty ? '[CHW Name]' : chwName;

    final t = _pdfTranslations[language] ?? {};
    String tr(String key, String fallback) => t[key] ?? fallback;

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
                  pw.Text(tr('referral_letter', 'REFERRAL LETTER'),
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 15,
                          color: PdfColors.white)),
                  pw.Text(tr('vision_screening', 'Vision Screening Programme'),
                      style: pw.TextStyle(
                          font: font, fontSize: 9, color: PdfColors.white)),
                ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                  pw.Text('${tr('date', 'Date')}: $screeningDate',
                      style: pw.TextStyle(
                          font: font, fontSize: 9, color: PdfColors.white)),
                  if (appointmentDate != null && appointmentDate.isNotEmpty)
                    pw.Text('${tr('appt', 'Appt')}: $appointmentDate',
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
                child: _box(tr('to', 'TO'), '${tr('eye_specialist', 'The Eye Specialist')}\n$facility', font, fontBold)),
            pw.SizedBox(width: 10),
            pw.Expanded(
                child: _box(tr('from', 'FROM'), chwId.isNotEmpty ? '$chw\n$chwTitle\n${tr('badge_id', 'Badge ID')}: $chwId' : '$chw\n$chwTitle', font, fontBold)),
          ]),
          pw.SizedBox(height: 14),
          pw.Text(tr('patient_details', 'PATIENT DETAILS'),
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFB),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFEEF2F6))),
            child: pw.Column(children: [
              _kv(tr('name', 'Name'), patient['name'] ?? '', font, fontBold),
              _kv(tr('patient_id', 'Patient ID'), patient['id'] ?? '', font, fontBold),
              _kv(tr('age_sex', 'Age / Sex'),
                  '${patient['age']} yrs  ${patient['gender'] == 'M' ? tr('male', 'Male') : tr('female', 'Female')}',
                  font, fontBold),
              _kv(tr('village', 'Village'), patient['village'] ?? '', font, fontBold),
              if ((patient['phone'] ?? '').isNotEmpty)
                _kv('Phone', patient['phone']!, font, fontBold),
              if (conditions.isNotEmpty)
                _kv(tr('conditions', 'Conditions'), conditions.join(', '), font, fontBold),
              if (appointmentDate != null && appointmentDate.isNotEmpty)
                _kv(tr('appointment', 'Appointment'), appointmentDate, font, fontBold),
            ]),
          ),
          pw.SizedBox(height: 14),
          pw.Text(tr('va_results', 'VISUAL ACUITY RESULTS'),
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(tr('distance_vision', 'Distance Vision (Monocular - Tumbling E)'),
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.SizedBox(height: 6),
          if (eyeResults.isEmpty)
            pw.Text('No visual acuity data recorded.',
                style: pw.TextStyle(font: font, fontSize: 10))
          else
            ...eyeResults.map((r) => _vaRow(r, font, fontBold, tr)),
          pw.SizedBox(height: 14),
          pw.Text(tr('reason', 'REASON FOR REFERRAL'),
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFEF4444))),
            child: pw.Text(
              tr('reason_body', 'Visual acuity below 6/12 detected in one or more eyes during community vision screening. Further examination and management is recommended.'),
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
          if (chwId.isNotEmpty)
            pw.Text('${tr('badge_id', 'Badge ID')}: $chwId',
                style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text('${tr('date', 'Date')}: $screeningDate',
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
    required String chwId,
    required List<String> conditions,
    required String language,
  }) async {
    final font     = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final chw = chwName.isEmpty ? '[CHW Name]' : chwName;
    final t = _pdfTranslations[language] ?? {};
    String tr(String key, String fallback) => t[key] ?? fallback;

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
                  pw.Text(tr('vision_screening', 'VISION SCREENING RESULT'),
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 15,
                          color: PdfColors.white)),
                  pw.Text('Community Eye Health Programme',
                      style: pw.TextStyle(
                          font: font, fontSize: 9, color: PdfColors.white)),
                ]),
                pw.Text('${tr('date', 'Date')}: $screeningDate',
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
          pw.Text(tr('patient_details', 'PATIENT DETAILS'),
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFB),
                border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFEEF2F6))),
            child: pw.Column(children: [
              _kv(tr('name', 'Name'), patient['name'] ?? '', font, fontBold),
              _kv(tr('patient_id', 'Patient ID'), patient['id'] ?? '', font, fontBold),
              _kv(tr('age_sex', 'Age / Sex'),
                  '${patient['age']} yrs  ${patient['gender'] == 'M' ? tr('male', 'Male') : tr('female', 'Female')}',
                  font, fontBold),
              _kv(tr('village', 'Village'), patient['village'] ?? '', font, fontBold),
              if ((patient['phone'] ?? '').isNotEmpty)
                _kv('Phone', patient['phone']!, font, fontBold),
              if (conditions.isNotEmpty)
                _kv(tr('conditions', 'Conditions'), conditions.join(', '), font, fontBold),
            ]),
          ),
          pw.SizedBox(height: 14),
          pw.Text(tr('va_results', 'VISUAL ACUITY RESULTS'),
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(tr('distance_vision', 'Distance Vision (Monocular - Tumbling E)'),
              style: pw.TextStyle(font: font, fontSize: 9)),
          pw.SizedBox(height: 6),
          if (eyeResults.isEmpty)
            pw.Text('No visual acuity data recorded.',
                style: pw.TextStyle(font: font, fontSize: 10))
          else
            ...eyeResults.map((r) => _vaRowGreen(r, font, fontBold, tr)),
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
          if (chwId.isNotEmpty)
            pw.Text('${tr('badge_id', 'Badge ID')}: $chwId',
                style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text('${tr('date', 'Date')}: $screeningDate',
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
    required String chwId,
    required String? appointmentDate,
    required List<String> conditions,
    String language = 'English Only',
  }) async {
    final doc = await _buildReferralDoc(
      patient: patient, eyeResults: eyeResults,
      screeningDate: screeningDate, facility: facility,
      chwName: chwName, chwTitle: chwTitle, chwId: chwId,
      appointmentDate: appointmentDate, conditions: conditions,
      language: language,
    );
    return _save(doc,
        'Referral_${(patient['name'] ?? 'patient').replaceAll(' ', '_')}_${screeningDate}_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<String> generatePassResultPdf({
    required Map<String, String> patient,
    required List<Map<String, dynamic>> eyeResults,
    required String screeningDate,
    required String chwName,
    required String chwTitle,
    required String chwId,
    required List<String> conditions,
    String language = 'English Only',
  }) async {
    final doc = await _buildPassDoc(
      patient: patient, eyeResults: eyeResults,
      screeningDate: screeningDate,
      chwName: chwName, chwTitle: chwTitle, chwId: chwId,
      conditions: conditions,
      language: language,
    );
    return _save(doc,
        'Result_${(patient['name'] ?? 'patient').replaceAll(' ', '_')}_${screeningDate}_${DateTime.now().millisecondsSinceEpoch}.pdf');
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
      Map<String, dynamic> r, pw.Font font, pw.Font bold,
      String Function(String, String) tr) {
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
          pw.Text(eye == 'OD'
              ? tr('right_eye', 'Right Eye (OD)')
              : tr('left_eye', 'Left Eye (OS)'),
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
      Map<String, dynamic> r, pw.Font font, pw.Font bold,
      String Function(String, String) tr) {
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
          pw.Text(eye == 'OD'
              ? tr('right_eye', 'Right Eye (OD)')
              : tr('left_eye', 'Left Eye (OS)'),
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
