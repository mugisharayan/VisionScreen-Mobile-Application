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
      'title': 'When to Refer a Patient',
      'icon': Icons.assignment_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80',
      'body':
          'A referral is generated when a patient\'s visual acuity falls below the age-appropriate threshold:\n\n👶 Pre-school (3–5 yrs) — Refer if VA < 6/12\n🧒 Child (6–12 yrs) — Refer if VA < 6/9\n🧑 Adult (13–60 yrs) — Refer if VA < 6/12\n👴 Elderly (60+ yrs) — Refer if VA < 6/18\n\nAlso refer immediately if:\n• The patient reports sudden vision loss\n• One eye is significantly worse than the other\n• The patient has visible eye injury or infection',
      'tip': 'When in doubt, always refer. It is better to send a patient who does not need specialist care than to miss one who does.',
    },
    {
      'title': 'Generating the Referral',
      'icon': Icons.note_add_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80',
      'body':
          'After a test result shows "Refer", tap "Generate Referral" on the results screen.\n\nThe referral document is auto-filled with:\n✓ Patient name, age, gender, village\n✓ Visual acuity scores (OD, OS, OU)\n✓ Date of screening\n✓ Screened by (your name & health centre)\n✓ Reason for referral\n\nYou then need to:\n1. Select the referral facility\n2. Set priority (Routine or Urgent)\n3. Set appointment date\n4. Add any clinical notes\n5. Tap "Save Referral"',
      'tip': 'Always select the nearest facility first — long travel distances reduce the chance the patient will attend.',
    },
    {
      'title': 'Priority Levels',
      'icon': Icons.priority_high_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=600&q=80',
      'body':
          'VisionScreen has two referral priority levels:\n\n🟡 ROUTINE\n• VA is reduced but not severely\n• Patient is stable\n• Appointment within 4–6 weeks\n• Example: Adult with VA 6/18\n\n🔴 URGENT\n• VA is severely reduced (≤ 6/36)\n• Sudden vision loss reported\n• Visible eye injury or infection\n• Appointment within 1 week\n• Notify your supervisor immediately\n\nAlways explain the priority level to the patient so they understand the urgency.',
      'tip': 'For urgent referrals, call the facility in advance to book the appointment — do not just send the patient.',
    },
    {
      'title': 'SMS & Patient Notification',
      'icon': Icons.sms_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=600&q=80',
      'body':
          'VisionScreen can send an SMS reminder to the patient with their appointment details.\n\nThe SMS includes:\n• Patient name\n• Referral facility name\n• Appointment date\n• Your contact number\n\nTo enable SMS:\n1. Go to Settings\n2. Turn on "SMS Notifications"\n3. Ensure the patient\'s phone number was entered during registration\n\nIf the patient has no phone, give them a printed referral slip or write the details on paper.',
      'tip': 'Always confirm the phone number with the patient before sending — a wrong number means a missed appointment.',
    },
    {
      'title': 'Tracking & Follow-Up',
      'icon': Icons.track_changes_rounded,
      'color': Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1504868584819-f8e8b4b6d7e3?w=600&q=80',
      'body':
          'After generating a referral, track its status in the Referrals tab:\n\n🟡 Pending — Referral created, not yet communicated\n🔵 Notified — Patient has been informed\n🟣 Attended — Patient visited the facility\n🟢 Completed — Treatment outcome recorded\n🔴 Overdue — Patient missed appointment\n⚫ Cancelled — Referral withdrawn\n\nYour job as a CHW is to follow up on every referral. Call or visit the patient if they are overdue.\n\nUpdate the status in the app after each follow-up so the programme data stays accurate.',
      'tip': 'Set a reminder on your phone for every referral due date — do not rely on memory alone.',
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
                Text('Module 4',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.2)),
                Text('Referral Generation',
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
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4)),
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
                    content: Text('Module 4 completed! All modules done! 🎓',
                        style: GoogleFonts.ibmPlexSans(fontSize: 12)),
                    backgroundColor: const Color(0xFFF59E0B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 3),
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
                    isLast ? 'Complete All Modules 🎓' : 'Next Step →',
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
