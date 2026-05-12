import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/module_illustrations.dart';

class Module1Screen extends StatefulWidget {
  final VoidCallback? onCompleted;
  const Module1Screen({super.key, this.onCompleted});
  @override
  State<Module1Screen> createState() => _Module1ScreenState();
}

class _Module1ScreenState extends State<Module1Screen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.person_add_rounded,
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&q=80',
      'title': 'Two Ways to Register',
      'body': 'VisionScreen supports two registration modes:\n\n'
          '1. INDIVIDUAL SCREENING\n'
          'Tap "New Screening" on the Home screen or the eye button on the bottom nav. '
          'You go directly to the new patient registration form.\n\n'
          '2. BULK MODE (Campaign)\n'
          'Tap "Bulk Mode" on the Home screen. Set up a campaign session first, '
          'then register patients one by one quickly during the session.',
      'tip': 'Individual screening is for detailed one-on-one assessments. Bulk mode is for schools, health camps and community outreach.',
    },
    {
      'icon': Icons.edit_note_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&q=80',
      'title': 'Required Registration Fields',
      'body': 'For INDIVIDUAL screening, fill in:\n\n'
          '• Full Name (required)\n'
          '• Date of Birth — tap the calendar to select (age auto-calculated)\n'
          '• Gender — tap M or F\n'
          '• Village / Area — or tap the GPS button to auto-detect\n'
          '• Phone Number (optional)\n'
          '• Eye Conditions — tap chips to select (Red Eyes, Blurred Vision, etc.)\n'
          '• Photo — tap the camera circle to take a photo\n\n'
          'Tap "Register & Select" to save and proceed to the eye test.',
      'tip': 'For BULK mode, only Name, Age, Gender, Phone and Eye Conditions are required — registration takes under 15 seconds per patient.',
    },
    {
      'icon': Icons.child_care_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80',
      'title': 'Age Groups & Thresholds',
      'body': 'The app automatically assigns an age group based on the patient\'s age:\n\n'
          '• CHILD (under 18) — shown in blue\n'
          '• ADULT (18–60) — shown in teal\n'
          '• ELDERLY (over 60) — shown in red\n\n'
          'Age groups affect how results are displayed on patient cards and in analytics. '
          'The referral threshold is LogMAR > 0.5 (Snellen 6/18) for all age groups.',
      'tip': 'Always verify the patient\'s age carefully — it affects the age group badge shown on their card.',
    },
    {
      'icon': Icons.medical_information_rounded,
      'color': Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1494869042583-f6c911f04b4c?w=400&q=80',
      'title': 'Eye Conditions',
      'body': 'Before testing, record any current eye conditions the patient reports:\n\n'
          '• Red Eyes\n'
          '• Swollen Eyes\n'
          '• Eye Discharge\n'
          '• Blurred Vision\n'
          '• Eye Pain\n'
          '• Previous Surgery\n'
          '• Wears Glasses\n'
          '• Diabetes\n'
          '• Hypertension\n\n'
          'Tap each chip to select or deselect. Selected conditions are saved to the patient record and appear on the referral letter.',
      'tip': 'Conditions like Diabetes and Hypertension are important risk factors for vision problems — always ask about them.',
    },
    {
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/1529156069898-49953e39b3ac?w=400&q=80',
      'title': 'Patients Screen',
      'body': 'All registered patients appear in the Patients screen (bottom nav).\n\n'
          '• INDIVIDUAL patients — listed individually with their outcome badge\n'
          '• CAMPAIGN patients — grouped under a campaign card. Tap the card to see all patients in that campaign\n\n'
          'Use the search bar to find any patient by name, ID, village or facility. '
          'You can also filter by outcome (Pass/Refer/Pending) or age group.\n\n'
          'Long-press a patient card to delete. Long-press a campaign card to delete the entire campaign and all its patients.',
      'tip': 'Pull down to refresh the patients list after adding new screenings.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        _buildHeader(color),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildStepContent(step, color, key: ValueKey(_currentStep)),
          ),
        ),
        _buildNavBar(color, isLast),
      ]),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF134E4A), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MODULE 1', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 1.8)),
            Text('Patient Registration', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
            child: Text('${_currentStep + 1} / ${_steps.length}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: List.generate(_steps.length, (i) {
          final isDone = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(child: Row(children: [
            Expanded(child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: isDone || isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(99),
              ),
            )),
            if (i < _steps.length - 1) const SizedBox(width: 4),
          ]));
        })),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_steps[_currentStep]['title'] as String,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
          Text('${((_currentStep + 1) / _steps.length * 100).toInt()}% complete',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
        ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildStepContent(Map step, Color color, {required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Illustration
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Module1Illustration(color: color),
        ),
        const SizedBox(height: 20),
        Text(step['title'] as String,
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Text(step['body'] as String,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.7)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_rounded, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(step['tip'] as String,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), height: 1.5))),
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
          if (_currentStep > 0)
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFF0F4F7), borderRadius: BorderRadius.circular(12)),
                child: Text('← Back', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLast) {
                  widget.onCompleted?.call();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Module 1 completed! 🎉', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                    backgroundColor: color, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                  Navigator.pop(context);
                } else {
                  setState(() => _currentStep++);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(isLast ? 'Complete Module ✓' : 'Next Step →',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

