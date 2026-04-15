import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Module3Screen extends StatefulWidget {
  final VoidCallback? onCompleted;
  const Module3Screen({super.key, this.onCompleted});

  @override
  State<Module3Screen> createState() => _Module3ScreenState();
}

class _Module3ScreenState extends State<Module3Screen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'The Tumbling E Chart',
      'icon': Icons.remove_red_eye_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=600&q=80',
      'body':
          'The Tumbling E is a literacy-independent vision test — the patient does not need to read or write. Instead, they simply point in the direction the letter "E" is facing.\n\nThe E can face 4 directions:\n← Left\n→ Right\n↑ Up\n↓ Down\n\nThis makes it ideal for:\n• Children who cannot read\n• Elderly patients\n• Patients who speak different languages\n• Community health settings in Uganda',
      'tip': 'Before starting, demonstrate the 4 directions to the patient using your hand or a printed card.',
    },
    {
      'title': 'LogMAR & Visual Acuity',
      'icon': Icons.analytics_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80',
      'body':
          'Visual acuity (VA) is measured in Snellen notation (e.g. 6/6) and LogMAR:\n\n6/6 (LogMAR 0.0) — Normal vision\n6/9 (LogMAR 0.18) — Mild reduction\n6/12 (LogMAR 0.3) — Moderate reduction\n6/18 (LogMAR 0.5) — Significant reduction\n6/24 (LogMAR 0.6) — Severe reduction\n6/36 (LogMAR 0.8) — Very poor\n6/60 (LogMAR 1.0) — Near blind\n\nThe chart rows go from largest (6/60) at the top to smallest (6/5) at the bottom. The patient reads from top to bottom.',
      'tip': 'Always record the LAST ROW the patient reads correctly — not the first row they fail.',
    },
    {
      'title': 'Testing Each Eye',
      'icon': Icons.visibility_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1638202993928-7267aad84c31?w=600&q=80',
      'body':
          'Always test each eye separately:\n\n1. Right Eye (OD) first\n   • Ask patient to cover LEFT eye with a card\n   • Do NOT press on the eye\n   • Test all rows from top to bottom\n   • Record the last row read correctly\n\n2. Left Eye (OS) second\n   • Ask patient to cover RIGHT eye\n   • Repeat the same process\n\n3. Both Eyes (OU) optional\n   • Test with both eyes open\n   • Record binocular result\n\nTap "Switch Eye" in the app to move between eyes.',
      'tip': 'Use an opaque card or folded paper to cover the eye — never the patient\'s hand (they may peek through fingers).',
    },
    {
      'title': 'Recording Responses',
      'icon': Icons.touch_app_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600&q=80',
      'body':
          'How to record responses in VisionScreen:\n\n1. The app shows the current E direction randomly\n2. Ask the patient: "Which way is the E pointing?"\n3. Patient points or says the direction\n4. Tap the matching arrow button (↑ ↓ ← →)\n5. App records Correct ✓ or Wrong ✗ automatically\n\nRow rules:\n• 3 or more correct on a row = patient can see that size\n• 2 or more wrong on a row = stop and record previous row\n• Move to next row using "Next Row →" button',
      'tip': 'Give the patient enough time to respond — especially elderly patients. Do not rush them.',
    },
    {
      'title': 'Pass, Refer & High Risk',
      'icon': Icons.assignment_turned_in_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1516307365426-bea591f05011?w=600&q=80',
      'body':
          'After completing both eyes, the app calculates the result:\n\n✅ PASS — VA meets or exceeds the age threshold\n   No referral needed. Advise patient to return in 1 year.\n\n⚠️ REFER — VA is below the age threshold\n   Generate a referral to the nearest eye clinic.\n\n🔴 HIGH RISK — VA is severely reduced (≤ 6/36)\n   Urgent referral required. Notify supervisor.\n\nAlways explain the result to the patient in simple terms before they leave.',
      'tip': 'Never tell a patient they have "bad eyes" — say "we recommend a specialist check" to avoid causing distress.',
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
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _buildStepContent(step, color,
                    key: ValueKey(_currentStep)),
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
                Text('Module 3',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.2)),
                Text('Vision Testing',
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
              Flexible(
                child: Text(_steps[_currentStep]['title'] as String,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              Text(
                  '${((_currentStep + 1) / _steps.length * 100).toInt()}% complete',
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
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                step['image'] as String,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
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
                    content: Text('Module 3 completed! 🎉',
                        style: GoogleFonts.ibmPlexSans(fontSize: 12)),
                    backgroundColor: const Color(0xFF8B5CF6),
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
                child: Center(
                  child: Text(
                    isLast ? 'Complete Module ✓' : 'Next Step →',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
