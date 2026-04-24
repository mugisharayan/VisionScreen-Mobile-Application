import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Module4Screen extends StatefulWidget {
  final VoidCallback? onCompleted;
  const Module4Screen({super.key, this.onCompleted});
  @override
  State<Module4Screen> createState() => _Module4ScreenState();
}

class _Module4ScreenState extends State<Module4Screen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.warning_rounded,
      'color': Color(0xFFEF4444),
      'image': 'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=400&q=80',
      'title': 'When to Refer a Patient',
      'body': 'A patient is automatically flagged for referral when:\n\n'
          '• Any eye has LogMAR > 0.5 (Snellen worse than 6/18)\n'
          '• Near vision LogMAR > 0.5 (individual screening only)\n\n'
          'The app shows a red "REFER" badge and a "Referral Recommended" banner on the summary screen.\n\n'
          'Common reasons for referral:\n'
          '• Uncorrected refractive error (needs glasses)\n'
          '• Cataract\n'
          '• Glaucoma\n'
          '• Diabetic retinopathy\n'
          '• Other eye diseases',
      'tip': 'Always explain to the patient why they are being referred and what to expect at the eye clinic.',
    },
    {
      'icon': Icons.description_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=400&q=80',
      'title': 'Generating a Referral Letter',
      'body': 'To generate a referral letter:\n\n'
          'INDIVIDUAL SCREENING:\n'
          '1. Complete the eye test\n'
          '2. On the summary screen, tap "Generate Referral Letter"\n'
          '3. Select the referral facility from the dropdown\n'
          '4. Set an appointment date\n'
          '5. Enter CHW name and title\n'
          '6. Tap "Preview Letter" to review\n'
          '7. Share via WhatsApp, PDF or print\n\n'
          'BULK MODE:\n'
          '1. On the result screen after each patient, tap "Generate Referral Letter"\n'
          '2. Same steps as above',
      'tip': 'The referral letter includes patient demographics, VA results, eye conditions, facility name and appointment date — all pre-filled from the screening data.',
    },
    {
      'icon': Icons.local_hospital_rounded,
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&q=80',
      'title': 'Referral Facilities',
      'body': 'The app includes a preset list of Uganda eye clinics:\n\n'
          '• Mulago National Referral Hospital Eye Clinic\n'
          '• Kampala Eye Clinic\n'
          '• Mengo Hospital Eye Department\n'
          '• Kibuli Muslim Hospital Eye Clinic\n'
          '• St. Francis Hospital Nsambya Eye Clinic\n'
          '• Jinja Regional Referral Hospital\n'
          '• Mbarara Regional Referral Hospital\n'
          '• Gulu Regional Referral Hospital\n'
          '• Other (specify)\n\n'
          'Select "Other" to type a custom facility name.',
      'tip': 'Always refer to the nearest facility — long distances reduce the chance the patient will actually attend.',
    },
    {
      'icon': Icons.notifications_active_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400&q=80',
      'title': 'Patient Notifications',
      'body': 'From the Patients screen, you can notify referred patients:\n\n'
          '• SMS REMINDER — sends a text to the patient\'s phone number\n'
          '• WHATSAPP REMINDER — sends a WhatsApp message with appointment details\n'
          '• CALL PATIENT — dials the patient\'s number directly\n\n'
          'To send a notification:\n'
          '1. Open the Patients screen\n'
          '2. Find the referred patient\n'
          '3. Tap the bell icon (🔔) on their card\n'
          '4. Choose SMS, WhatsApp or Call\n\n'
          'Notifications help ensure patients actually attend their referral appointments.',
      'tip': 'Send a reminder 2–3 days before the appointment date for best attendance rates.',
    },
    {
      'icon': Icons.track_changes_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&q=80',
      'title': 'Tracking Referral Status',
      'body': 'Each referral has a status that you update manually:\n\n'
          '• PENDING — referral created, patient not yet attended\n'
          '• NOTIFIED — patient has been contacted\n'
          '• ATTENDED — patient attended the appointment\n'
          '• COMPLETED — treatment completed\n'
          '• OVERDUE — appointment date passed, patient not attended\n'
          '• CANCELLED — referral cancelled\n\n'
          'The Home screen "Referral Follow-Ups" section shows all pending and overdue referrals.\n\n'
          'The Notifications screen automatically alerts you when appointments are overdue or upcoming (within 3 days).',
      'tip': 'Update referral status after each follow-up call — this keeps your data accurate and helps track programme outcomes.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(children: [
        _buildHeader(color),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildStepContent(step, color, key: ValueKey(_currentStep)),
        )),
        _buildNavBar(color, isLast),
      ]),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF04091A), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Module 4', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 1.0)),
            Text('Referrals & Follow-Up', style: GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
            child: Text('${_currentStep + 1} / ${_steps.length}',
                style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: List.generate(_steps.length, (i) => Expanded(child: Row(children: [
          Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4,
              decoration: BoxDecoration(color: i <= _currentStep ? Colors.white : Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(99)))),
          if (i < _steps.length - 1) const SizedBox(width: 4),
        ])))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_steps[_currentStep]['title'] as String,
              style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
          Text('${((_currentStep + 1) / _steps.length * 100).toInt()}% complete',
              style: GoogleFonts.ibmPlexSans(fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ]),
      ]),
    );
  }

  Widget _buildStepContent(Map step, Color color, {required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Image.network(step['image'] as String, height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 160, color: color.withOpacity(0.15),
                    child: Icon(step['icon'] as IconData, size: 60, color: color))),
            Container(height: 160, decoration: BoxDecoration(gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                begin: Alignment.bottomCenter, end: Alignment.topCenter))),
            Positioned(bottom: 14, left: 14, child: Container(width: 44, height: 44,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                child: Icon(step['icon'] as IconData, color: Colors.white, size: 22))),
          ]),
        ),
        const SizedBox(height: 20),
        Text(step['title'] as String, style: GoogleFonts.barlow(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1A2A3D))),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Text(step['body'] as String, style: GoogleFonts.ibmPlexSans(fontSize: 13, color: const Color(0xFF1A2A3D), height: 1.7)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_rounded, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(step['tip'] as String, style: GoogleFonts.ibmPlexSans(fontSize: 12, color: const Color(0xFF1A2A3D), height: 1.5))),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildNavBar(Color color, bool isLast) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F7), borderRadius: BorderRadius.circular(12)),
                  child: Text('← Back', style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF5E7291)))),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: GestureDetector(
            onTap: () {
              if (isLast) {
                widget.onCompleted?.call();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Module 4 completed! All modules done! 🎓', style: GoogleFonts.ibmPlexSans(fontSize: 12, color: Colors.white)),
                  backgroundColor: color, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 3),
                ));
                Navigator.pop(context);
              } else {
                setState(() => _currentStep++);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(isLast ? 'Complete All Modules 🎓' : 'Next Step →',
                  style: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
          )),
        ]),
      ),
    );
  }
}
