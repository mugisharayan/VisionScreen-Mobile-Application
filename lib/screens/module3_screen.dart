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
      'icon': Icons.groups_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/1529156069898-49953e39b3ac?w=400&q=80',
      'title': 'What is Bulk Mode?',
      'body': 'Bulk Mode is designed for campaign screenings — schools, health camps, community outreach — where you need to screen many patients quickly.\n\n'
          'Key differences from individual screening:\n'
          '• Registration takes under 15 seconds per patient\n'
          '• No near vision test (distance only)\n'
          '• One-time light/brightness check for the whole session\n'
          '• All patients grouped under a campaign card\n'
          '• Session summary at the end with all results\n\n'
          'Tap "Bulk Mode" on the Home screen to start.',
      'tip': 'Bulk mode is ideal for school screenings where you may screen 50+ children in one session.',
    },
    {
      'icon': Icons.campaign_rounded,
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&q=80',
      'title': 'Setting Up a Campaign',
      'body': 'Before screening begins, set up the campaign session:\n\n'
          '1. CAMPAIGN NAME — e.g. "Nakawa Primary School Outreach"\n'
          '2. LOCATION / VENUE — e.g. "Nakawa, Kampala"\n'
          '3. TARGET GROUP — Children / Adults / Elderly / Mixed\n\n'
          'Tap "Start Screening Session" to create the campaign in the database and begin.\n\n'
          'The campaign is saved immediately — even if you close the app, the session data is preserved.',
      'tip': 'Use a descriptive campaign name that includes the location and date — e.g. "Mengo School · March 2026".',
    },
    {
      'icon': Icons.how_to_reg_rounded,
      'color': Color(0xFF8B5CF6),
      'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80',
      'title': 'Registering Each Patient',
      'body': 'For each patient in the session:\n\n'
          '1. Enter FULL NAME (required)\n'
          '2. Set AGE using the + / − buttons\n'
          '3. Select GENDER (M or F)\n'
          '4. Enter PHONE NUMBER (optional)\n'
          '5. Select EYE CONDITIONS (tap chips)\n\n'
          'Tap "Register & Start Eye Test" — the patient is saved to the database and the eye test begins immediately.\n\n'
          'After each patient\'s result, tap "Next Patient" to loop back to registration for the next person.',
      'tip': 'The session counter at the top shows how many patients have been screened so far — keep track of your queue.',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF3B82F6),
      'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80',
      'title': 'Session Summary',
      'body': 'When all patients are screened, tap "End Session & View Summary".\n\n'
          'The summary shows:\n'
          '• Campaign name, location and target group\n'
          '• Total screened, passed, referred and pass rate\n'
          '• Full list of all patients with their VA results and outcome badges\n'
          '• Referral facility for referred patients\n\n'
          'Tap "Done — Back to Home" to finish the session.\n\n'
          'For referred patients, tap "Generate Referral Letter" on the result screen before moving to the next patient.',
      'tip': 'Always generate referral letters for referred patients before ending the session — you can share them via WhatsApp immediately.',
    },
    {
      'icon': Icons.folder_special_rounded,
      'color': Color(0xFF0D9488),
      'image': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&q=80',
      'title': 'Campaigns in Patients Screen',
      'body': 'After a bulk session, the campaign appears as a card at the top of the Patients screen.\n\n'
          'The campaign card shows:\n'
          '• Campaign name and location\n'
          '• Total screened, passed, referred and pass rate\n\n'
          'Tap the card to open the Campaign Detail screen — all patients in the campaign are listed with full patient cards (same features as individual patients).\n\n'
          'Long-press a campaign card to delete the entire campaign and all its patients.\n\n'
          'Search for campaign patients by name in the search bar — they appear under "Campaign Patients".',
      'tip': 'Campaign stats update automatically whenever a patient is deleted or a new screening is added.',
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
            Text('Module 3', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.6), letterSpacing: 1.0)),
            Text('Bulk Mode & Campaigns', style: GoogleFonts.barlow(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
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
                  content: Text('Module 3 completed! 🎉', style: GoogleFonts.ibmPlexSans(fontSize: 12, color: Colors.white)),
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
                gradient: LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(isLast ? 'Complete Module ✓' : 'Next Step →',
                  style: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
          )),
        ]),
      ),
    );
  }
}
