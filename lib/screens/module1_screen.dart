import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      'title': 'Why Registration Matters',
      'icon': Icons.info_outline_rounded,
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80',
      'body':
          'Every patient must be registered before a vision test begins. Registration creates a permanent record that links test results, referrals, and follow-ups to the correct person.\n\nWithout accurate registration, results cannot be tracked over time and referrals may go to the wrong patient.',
      'tip': 'Always double-check the patient\'s name spelling before saving.',
    },
    {
      'title': 'Required Fields',
      'icon': Icons.assignment_ind_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80',
      'body':
          'The following fields are REQUIRED for every patient:\n\n• Full Name — as on their ID or birth certificate\n• Age — exact age in years (not estimated)\n• Gender — Male or Female\n• Village / Location — sub-county and district\n\nOptional but recommended:\n• Phone number (for SMS reminders)\n• Known eye conditions',
      'tip': 'Age is critical — it determines which pass/fail threshold is applied during the test.',
    },
    {
      'title': 'Age Groups & Thresholds',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1516307365426-bea591f05011?w=600&q=80',
      'body':
          'VisionScreen uses age to automatically select the correct clinical threshold:\n\n👶 Pre-school (3–5 yrs) → Pass: ≥ 6/12\n🧒 Child (6–12 yrs) → Pass: ≥ 6/9\n🧑 Adult (13–60 yrs) → Pass: ≥ 6/12\n👴 Elderly (60+ yrs) → Pass: ≥ 6/18\n\nIf the wrong age is entered, the system may give an incorrect Pass or Refer result.',
      'tip': 'For children who don\'t know their age, ask the parent or check the health card.',
    },
    {
      'title': 'Entering the Patient',
      'icon': Icons.edit_rounded,
      'color': Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=600&q=80',
      'body':
          'Step-by-step registration process:\n\n1. Tap "New Screening" on the Home screen\n2. Enter the patient\'s full name\n3. Enter exact age and select gender\n4. Enter phone number if available\n5. Enter village and district\n6. Tap "Proceed to Calibration"\n\nThe system will auto-save the record to local storage (SQLite) immediately.',
      'tip': 'You can register a patient even when offline — data syncs to MongoDB Atlas when internet is available.',
    },
    {
      'title': 'Reviewing & Editing',
      'icon': Icons.manage_search_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600&q=80',
      'body':
          'After registration, you can always find the patient in the Patients tab.\n\nFrom the patient detail screen you can:\n• View all past screening results\n• See referral history\n• Start a new screening\n• Generate a patient report\n\nAlways verify the patient\'s details before starting a new test to avoid mixing up records.',
      'tip': 'Use the search bar in the Patients tab to quickly find a patient by name, ID, or village.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(context, color),
          _buildProgressBar(color),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _buildStepContent(step, color, key: ValueKey(_currentStep)),
              ),
            ),
          ),
          _buildFooter(context, color, isLast),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF04091A), color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Module 1',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.2)),
                Text('Patient Registration',
                    style: GoogleFonts.barlow(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              '${_currentStep + 1} / ${_steps.length}',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color color) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (i) {
              final isDone = i < _currentStep;
              final isCurrent = i == _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone
                        ? color
                        : isCurrent
                            ? color.withOpacity(0.5)
                            : const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_steps[_currentStep]['title'] as String,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text('${((_currentStep + 1) / _steps.length * 100).toInt()}% complete',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8FA0B4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Map step, Color color, {required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                step['image'] as String,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: color.withOpacity(0.15),
                  child: Icon(step['icon'] as IconData, size: 60, color: color),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      color.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 14, left: 14,
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Icon(step['icon'] as IconData,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(step['title'] as String,
                        style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Body content card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Text(
            step['body'] as String,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3D5470),
                height: 1.75),
          ),
        ),
        const SizedBox(height: 12),
        // Tip card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb_rounded, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRO TIP',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(step['tip'] as String,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3D5470),
                            height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, Color color, bool isLast) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEF2F6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDE4EC)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF5E7291), size: 20),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLast) {
                  widget.onCompleted?.call();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Module 1 completed! 🎉',
                        style: GoogleFonts.ibmPlexSans(fontSize: 12)),
                    backgroundColor: const Color(0xFF0D9488),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                  Navigator.pop(context);
                } else {
                  setState(() => _currentStep++);
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Complete Module ✓' : 'Next Step →',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
