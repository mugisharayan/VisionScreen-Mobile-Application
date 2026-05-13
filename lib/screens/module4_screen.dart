import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/module_illustrations.dart';
import '../widgets/vs_toast.dart';
import '../widgets/vs_ui.dart';

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
      'image':
          'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=400&q=80',
      'title': 'When to Refer a Patient',
      'body':
          'A patient is automatically flagged for referral when:\n\n'
          '• Any eye has LogMAR > 0.5 (Snellen worse than 6/18)\n'
          '• Near vision LogMAR > 0.5 (individual screening only)\n\n'
          'The app shows a red "REFER" badge and a "Referral Recommended" banner on the summary screen.\n\n'
          'Common reasons for referral:\n'
          '• Uncorrected refractive error (needs glasses)\n'
          '• Cataract\n'
          '• Glaucoma\n'
          '• Diabetic retinopathy\n'
          '• Other eye diseases',
      'tip':
          'Always explain to the patient why they are being referred and what to expect at the eye clinic.',
    },
    {
      'icon': Icons.description_rounded,
      'image':
          'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=400&q=80',
      'title': 'Generating a Referral Letter',
      'body':
          'To generate a referral letter:\n\n'
          'INDIVIDUAL SCREENING:\n'
          '1. Complete the eye test\n'
          '2. On the summary screen, tap "Generate referral letter"\n'
          '3. Select the referral facility from the dropdown\n'
          '4. Set an appointment date\n'
          '5. Enter CHW name and title\n'
          '6. Tap "Preview Letter" to review\n'
          '7. Share via WhatsApp, PDF or print\n\n'
          'BULK MODE:\n'
          '1. On the result screen after each patient, tap "Generate referral letter"\n'
          '2. Same steps as above',
      'tip':
          'The referral letter includes patient demographics, VA results, eye conditions, facility name and appointment date — all pre-filled from the screening data.',
    },
    {
      'icon': Icons.local_hospital_rounded,
      'image':
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&q=80',
      'title': 'Referral Facilities',
      'body':
          'The app includes a preset list of Uganda eye clinics:\n\n'
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
      'tip':
          'Always refer to the nearest facility — long distances reduce the chance the patient will actually attend.',
    },
    {
      'icon': Icons.notifications_active_rounded,
      'image':
          'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400&q=80',
      'title': 'Patient Notifications',
      'body':
          'From the Patients screen, you can notify referred patients:\n\n'
          '• SMS REMINDER — sends a text to the patient\'s phone number\n'
          '• WHATSAPP REMINDER — sends a WhatsApp message with appointment details\n'
          '• CALL PATIENT — dials the patient\'s number directly\n\n'
          'To send a notification:\n'
          '1. Open the Patients screen\n'
          '2. Find the referred patient\n'
          '3. Tap the bell icon (🔔) on their card\n'
          '4. Choose SMS, WhatsApp or Call\n\n'
          'Notifications help ensure patients actually attend their referral appointments.',
      'tip':
          'Send a reminder 2–3 days before the appointment date for best attendance rates.',
    },
    {
      'icon': Icons.track_changes_rounded,
      'image':
          'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&q=80',
      'title': 'Tracking Referral Status',
      'body':
          'Each referral has a status that you update manually:\n\n'
          '• PENDING — referral created, patient not yet attended\n'
          '• NOTIFIED — patient has been contacted\n'
          '• ATTENDED — patient attended the appointment\n'
          '• COMPLETED — treatment completed\n'
          '• OVERDUE — appointment date passed, patient not attended\n'
          '• CANCELLED — referral cancelled\n\n'
          'The Activity screen follow-up view shows pending and overdue referrals.\n\n'
          'The Notifications screen automatically alerts you when appointments are overdue or upcoming (within 3 days).',
      'tip':
          'Update referral status after each follow-up call — this keeps your data accurate and helps track programme outcomes.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    const color = Color(0xFFE11D48);
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(color),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildStepContent(
                step,
                color,
                key: ValueKey(_currentStep),
              ),
            ),
          ),
          _buildNavBar(color, isLast),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF134E4A), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VsBackTile(onTap: () => Navigator.pop(context), size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MODULE 4',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 1.8,
                          ),
                        ),
                        Text(
                          'Referrals & Follow-Up',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${_currentStep + 1} / ${_steps.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(
                  _steps.length,
                  (i) => Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _currentStep
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        if (i < _steps.length - 1) const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _steps[_currentStep]['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '${((_currentStep + 1) / _steps.length * 100).toInt()}% complete',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(Map step, Color color, {required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Module4Illustration(color: color),
          ),
          const SizedBox(height: 20),
          Text(
            step['title'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              step['body'] as String,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF334155),
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step['tip'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavBar(Color color, bool isLast) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _currentStep--),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5E7291),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (isLast) {
                      widget.onCompleted?.call();
                      VsToast.showText(
                        context,
                        'Module 4 completed.',
                        backgroundColor: color,
                        duration: const Duration(seconds: 3),
                      );
                      Navigator.pop(context);
                    } else {
                      setState(() => _currentStep++);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isLast ? 'Complete module' : 'Next step',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
