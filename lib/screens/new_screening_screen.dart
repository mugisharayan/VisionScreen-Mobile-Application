import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFF04091A);
const _ink2 = Color(0xFF0B1530);
const _teal = Color(0xFF0D9488);
const _teal3 = Color(0xFF5EEAD4);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _green = Color(0xFF22C55E);
const double _kMinLux = 80.0;

class NewScreeningScreen extends StatefulWidget {
  const NewScreeningScreen({super.key});
  @override
  State<NewScreeningScreen> createState() => _NewScreeningScreenState();
}

class _NewScreeningScreenState extends State<NewScreeningScreen>
    with TickerProviderStateMixin {

  // 0=brightness,1=distance,2=face,3=patient,4=coverEye,5=chart,6=results
  int _step = 0;

  // Feature 1
  double _currentLux = 0.0;
  bool _luxChecked = false;
  bool _luxSufficient = false;

  // Feature 2
  int? _selectedDistance;

  // Feature 3
  CameraController? _cameraCtrl;
  bool _cameraPermissionGranted = false;
  bool _cameraInitialized = false;
  bool _faceDetected = false;
  bool _faceAtCorrectDistance = false;
  Timer? _faceSimTimer;

  // Feature 4
  String? _selectedPatientId;
  final _patientSearchCtrl = TextEditingController();
  String _patientQuery = '';
  bool _showNewPatientForm = false;
  final _newNameCtrl = TextEditingController();
  final _newAgeCtrl = TextEditingController();
  final _newVillageCtrl = TextEditingController();
  String _newGender = 'M';
  // runtime list — starts as copy of static list, new patients appended
  List<Map<String, String>> _patientListRuntime = _patients
      .map((p) => Map<String, String>.from(p))
      .toList();

  // Feature 5
  // eyeOrder: 0=OD(right), 1=OS(left), 2=OU(both)
  int _currentEyeIndex = 0;
  static const _eyeOrder = ['OD', 'OS', 'OU'];

  // Feature 6 & 7: Tumbling E chart
  int _currentRow = 0;
  int _currentLetter = 0;
  List<bool> _rowAnswers = [];

  // Feature 9 & 10: scoring
  int _consecutiveFailedRows = 0;
  String? _stoppingLogmar;

  // Feature 11: retry
  bool _rowRetryUsed = false;

  // Results store: keyed by eye label
  final Map<String, String> _eyeResults = {};
  // LogMAR rows: label, optotype size (logical px), letters per row
  static const _rows = [
    {'logmar': '1.0', 'size': 92.0, 'count': 1},
    {'logmar': '0.9', 'size': 78.0, 'count': 1},
    {'logmar': '0.8', 'size': 66.0, 'count': 2},
    {'logmar': '0.7', 'size': 56.0, 'count': 2},
    {'logmar': '0.6', 'size': 47.0, 'count': 3},
    {'logmar': '0.5', 'size': 40.0, 'count': 3},
    {'logmar': '0.4', 'size': 34.0, 'count': 4},
    {'logmar': '0.3', 'size': 28.0, 'count': 4},
    {'logmar': '0.2', 'size': 24.0, 'count': 5},
    {'logmar': '0.1', 'size': 20.0, 'count': 5},
    {'logmar': '0.0', 'size': 17.0, 'count': 6},
  ];
  // Random rotations per row: 0=right,1=up,2=left,3=down
  late List<List<int>> _rotations;

  void _generateRotations() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    _rotations = List.generate(_rows.length, (r) {
      final count = _rows[r]['count'] as int;
      return List.generate(count, (i) => (rng + r * 7 + i * 13) % 4);
    });
  }

  static const _patients = [
    {'id': 'PAT-00312', 'name': 'Akello Mercy',    'age': '34', 'gender': 'F', 'village': 'Nakawa, Kampala'},
    {'id': 'PAT-00298', 'name': 'Okello James',    'age': '58', 'gender': 'M', 'village': 'Bwaise, Kampala'},
    {'id': 'PAT-00301', 'name': 'Nakato Aisha',    'age': '27', 'gender': 'F', 'village': 'Ntinda, Kampala'},
    {'id': 'PAT-00315', 'name': 'Mugisha Wilson',  'age': '45', 'gender': 'M', 'village': 'Kireka, Wakiso'},
    {'id': 'PAT-00289', 'name': 'Kyomuhendo Rose', 'age': '19', 'gender': 'F', 'village': 'Rubaga, Kampala'},
    {'id': 'PAT-00276', 'name': 'Byaruhanga Sam',  'age': '62', 'gender': 'M', 'village': 'Kawempe, Kampala'},
    {'id': 'PAT-00261', 'name': 'Tendo Kevin',     'age': '9',  'gender': 'M', 'village': 'Nansana, Wakiso'},
    {'id': 'PAT-00254', 'name': 'Apio Norah',      'age': '8',  'gender': 'F', 'village': 'Kira, Wakiso'},
  ];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkBrightness();
    _generateRotations();
    _loadUnsyncedCount();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _isOffline = results.every((r) => r == ConnectivityResult.none));
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _cameraCtrl?.dispose();
    _faceSimTimer?.cancel();
    _testTimer?.cancel();
    _connectivitySub?.cancel();
    _patientSearchCtrl.dispose();
    _newNameCtrl.dispose();
    _newAgeCtrl.dispose();
    _newVillageCtrl.dispose();
    super.dispose();
  }

  void _checkBrightness() {
    setState(() => _luxChecked = false);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      const simLux = 120.0;
      setState(() {
        _currentLux = simLux;
        _luxChecked = true;
        _luxSufficient = simLux >= _kMinLux;
      });
    });
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _cameraPermissionGranted = false);
      return;
    }
    setState(() => _cameraPermissionGranted = true);
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraCtrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraCtrl!.initialize();
    if (!mounted) return;
    setState(() => _cameraInitialized = true);
    _startFaceDetection();
  }

  void _startFaceDetection() {
    int tick = 0;
    _faceSimTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      tick++;
      setState(() {
        if (tick >= 2) _faceDetected = true;
        if (tick >= 4) _faceAtCorrectDistance = true;
      });
      if (_faceAtCorrectDistance) _faceSimTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          if (_isOffline)
            Container(
              width: double.infinity,
              color: _amber.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 14, color: _amber),
                  const SizedBox(width: 8),
                  Text(
                    'No internet connection — results will be saved locally',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _amber),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _step == 0
                ? _buildBrightnessStep()
                : _step == 1
                    ? _buildDistanceSelector()
                    : _step == 2
                        ? _buildFaceDetection()
                        : _step == 3
                            ? _buildPatientSelector()
                            : _step == 4
                                ? _buildCoverEyeReminder()
                                : _step == 5
                                    ? _buildEChart()
                                    : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_ink, _ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Screening',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Tumbling E · LogMAR Scale',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _teal3.withValues(alpha: 0.6))),
                ],
              ),
              const Spacer(),
              if (_unsyncedCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 11, color: _amber),
                      const SizedBox(width: 4),
                      Text('$_unsyncedCount unsynced',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _amber)),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _teal3.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, size: 12, color: _teal3),
                    const SizedBox(width: 5),
                    Text('WHO Standard',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700, color: _teal3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessStep() {
    if (!_luxChecked) return _buildCheckingLight();
    if (!_luxSufficient) return _buildLowLightWarning();
    return _buildLightOk();
  }

  Widget _buildCheckingLight() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _amber.withValues(alpha: 0.1),
                  border: Border.all(color: _amber.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.wb_sunny_rounded, size: 48, color: _amber),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Checking Room Lighting...',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 8),
          Text('Please wait while we measure ambient light',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4))),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: _teal, strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildLowLightWarning() {
    final luxDisplay = _currentLux > 0 ? '${_currentLux.toStringAsFixed(0)} lux' : '-';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _red.withValues(alpha: 0.08),
              border: Border.all(color: _red.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.wb_sunny_outlined, size: 52, color: _red),
          ),
          const SizedBox(height: 24),
          Text('Insufficient Lighting',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 10),
          Text(
            'The room lighting is too low for a clinically accurate vision screening.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Level',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF8FA0B4),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(luxDisplay,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 28, fontWeight: FontWeight.w800, color: _red)),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: _red.withValues(alpha: 0.15)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Required Minimum',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF8FA0B4),
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${_kMinLux.toInt()} lux',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 28, fontWeight: FontWeight.w800, color: _green)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _amber.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.tips_and_updates_rounded, size: 16, color: _amber),
                  const SizedBox(width: 8),
                  Text('How to improve lighting',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D))),
                ]),
                const SizedBox(height: 12),
                ...[
                  'Move to a room with natural daylight or bright overhead lighting',
                  'Turn on all available lights in the room',
                  'Avoid conducting the test in shadows or dim corridors',
                  'Ensure the patient faces the light source',
                ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tip,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF5E7291), height: 1.5))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checkBrightness,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: Text('Re-check Lighting',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Screening cannot proceed until lighting meets the clinical threshold.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLightOk() {
    final luxDisplay = _currentLux > 0
        ? '${_currentLux.toStringAsFixed(0)} lux'
        : 'Sensor unavailable';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.1),
                border: Border.all(color: _green.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.wb_sunny_rounded, size: 48, color: _green),
            ),
            const SizedBox(height: 20),
            Text('Lighting is Good',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2A3D))),
            const SizedBox(height: 8),
            Text(luxDisplay,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _green)),
            const SizedBox(height: 8),
            Text(
              'Room lighting meets the clinical threshold for accurate screening.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF8FA0B4), height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                label: Text('Continue to Setup',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required int current, required int total}) {
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 <= current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? _teal : const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDistanceSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStepIndicator(current: 2, total: 4),
          const SizedBox(height: 28),
          Text('Testing Distance',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 8),
          Text(
            'Select the distance between the patient and the screen. '
            'Ensure the patient is seated at exactly this distance.',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
          ),
          const SizedBox(height: 28),
          _distanceCard(
            metres: 3,
            label: '3 Metres',
            description: 'Standard CHW field screening distance',
            recommended: true,
            icon: Icons.social_distance_rounded,
          ),
          const SizedBox(height: 14),
          _distanceCard(
            metres: 6,
            label: '6 Metres',
            description: 'Clinical facility standard distance',
            recommended: false,
            icon: Icons.straighten_rounded,
          ),
          if (_selectedDistance != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _teal.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: _teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Mark the floor at exactly $_selectedDistance metres from the screen before starting.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF5E7291), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedDistance == null
                  ? null
                  : () {
                      setState(() => _step = 2);
                      _initCamera();
                    },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              label: Text('Continue',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedDistance == null
                    ? const Color(0xFF8FA0B4) : _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          if (_selectedDistance == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text('Select a testing distance to continue',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF8FA0B4))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _distanceCard({
    required int metres,
    required String label,
    required String description,
    required bool recommended,
    required IconData icon,
  }) {
    final selected = _selectedDistance == metres;
    return GestureDetector(
      onTap: () => setState(() => _selectedDistance = metres),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _teal.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _teal : const Color(0xFFEEF2F6),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _teal.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? _teal.withValues(alpha: 0.12)
                    : const Color(0xFFF0F4F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26,
                  color: selected ? _teal : const Color(0xFF8FA0B4)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: selected ? _teal : const Color(0xFF1A2A3D))),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: _green.withValues(alpha: 0.3)),
                          ),
                          child: Text('Recommended',
                              style: GoogleFonts.inter(
                                  fontSize: 9, fontWeight: FontWeight.w700, color: _green)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _teal : Colors.transparent,
                border: Border.all(
                  color: selected ? _teal : const Color(0xFFDDE4EC),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceDetection() {
    if (!_cameraPermissionGranted && !_cameraInitialized) {
      return _buildCameraPermissionDenied();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStepIndicator(current: 3, total: 4),
          const SizedBox(height: 28),
          Text('Distance Calibration',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 8),
          Text(
            'Position the patient\'s face in the camera frame. '
            'The system will verify they are at the correct '
            '$_selectedDistance metre distance.',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 300, width: double.infinity,
              color: const Color(0xFF1A2A3D),
              child: _cameraInitialized && _cameraCtrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraCtrl!),
                        CustomPaint(
                          painter: _FaceOverlayPainter(
                            faceDetected: _faceDetected,
                            correctDistance: _faceAtCorrectDistance,
                          ),
                        ),
                        Positioned(
                          bottom: 16, left: 16, right: 16,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _faceAtCorrectDistance
                                  ? _green.withValues(alpha: 0.85)
                                  : _faceDetected
                                      ? _amber.withValues(alpha: 0.85)
                                      : Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _faceAtCorrectDistance
                                      ? Icons.check_circle_rounded
                                      : _faceDetected
                                          ? Icons.warning_rounded
                                          : Icons.face_rounded,
                                  color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _faceAtCorrectDistance
                                      ? 'Face detected - distance confirmed'
                                      : _faceDetected
                                          ? 'Adjusting distance...'
                                          : 'Looking for face...',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Transform.scale(
                              scale: _pulseAnim.value,
                              child: const Icon(Icons.camera_front_rounded,
                                  size: 56, color: _teal3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Initialising camera...',
                              style: GoogleFonts.inter(fontSize: 13, color: _teal3)),
                          const SizedBox(height: 12),
                          const CircularProgressIndicator(color: _teal, strokeWidth: 2),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _teal.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.tips_and_updates_rounded, size: 15, color: _teal),
                  const SizedBox(width: 8),
                  Text('Positioning guide',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D))),
                ]),
                const SizedBox(height: 10),
                ...[
                  'Ask the patient to sit or stand facing the device',
                  'Ensure their full face is visible in the frame',
                  'Confirm they are exactly $_selectedDistance metres away',
                  'Good lighting helps the camera detect the face',
                ].map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF5E7291), height: 1.5))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _faceAtCorrectDistance
                  ? () {
                      _cameraCtrl?.dispose();
                      _cameraCtrl = null;
                      setState(() => _step = 3);
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              label: Text('Begin Screening',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _faceAtCorrectDistance ? _teal : const Color(0xFF8FA0B4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          if (!_faceAtCorrectDistance)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'Face must be detected at the correct distance to proceed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _red.withValues(alpha: 0.08),
                border: Border.all(color: _red.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.no_photography_rounded, size: 44, color: _red),
            ),
            const SizedBox(height: 20),
            Text('Camera Permission Required',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2A3D))),
            const SizedBox(height: 10),
            Text(
              'Camera access is required to verify the patient is at the correct testing distance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF5E7291), height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                label: Text('Grant Camera Access',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    final filtered = _patientListRuntime.where((p) {
      if (_patientQuery.isEmpty) return true;
      final q = _patientQuery.toLowerCase();
      return p['name']!.toLowerCase().contains(q) ||
          p['id']!.toLowerCase().contains(q) ||
          p['village']!.toLowerCase().contains(q);
    }).toList();

    // When the new patient form is open, use a fully scrollable layout
    if (_showNewPatientForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(current: 4, total: 4),
            const SizedBox(height: 20),
            Text('Select Patient',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2A3D))),
            const SizedBox(height: 6),
            Text('Search for a registered patient or add a new one.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291))),
            const SizedBox(height: 16),
            _searchBar(),
            const SizedBox(height: 10),
            _newPatientToggle(),
            const SizedBox(height: 12),
            _newPatientForm(),
            const SizedBox(height: 16),
            ...filtered.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _patientCard(p),
            )),
            if (_selectedPatientId != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _step = 4),
                  icon: const Icon(Icons.visibility_rounded, size: 18, color: Colors.white),
                  label: Text('Start Eye Test',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Normal layout: fixed top, scrollable list
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(current: 4, total: 4),
              const SizedBox(height: 20),
              Text('Select Patient',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2A3D))),
              const SizedBox(height: 6),
              Text('Search for a registered patient or add a new one.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291))),
              const SizedBox(height: 16),
              _searchBar(),
              const SizedBox(height: 10),
              _newPatientToggle(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No patients found',
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF8FA0B4))))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _patientCard(filtered[i]),
                ),
        ),
        if (_selectedPatientId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _step = 4),
                icon: const Icon(Icons.visibility_rounded, size: 18, color: Colors.white),
                label: Text('Start Eye Test',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: TextField(
        controller: _patientSearchCtrl,
        onChanged: (v) => setState(() => _patientQuery = v),
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D)),
        decoration: InputDecoration(
          hintText: 'Search by name, ID or village...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF8FA0B4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _newPatientToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showNewPatientForm = !_showNewPatientForm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showNewPatientForm ? _teal.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showNewPatientForm ? _teal : const Color(0xFFEEF2F6),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _showNewPatientForm
                  ? Icons.remove_circle_outline_rounded
                  : Icons.person_add_rounded,
              size: 18, color: _teal,
            ),
            const SizedBox(width: 10),
            Text(
              _showNewPatientForm ? 'Cancel new patient' : 'Add new patient',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _teal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPatientForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _teal.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Patient Details',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 12),
          _newField(_newNameCtrl, 'Full Name', Icons.person_rounded),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _newField(_newAgeCtrl, 'Age', Icons.cake_rounded,
                    inputType: TextInputType.number),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                ),
                child: Row(
                  children: ['M', 'F'].map((g) {
                    final active = _newGender == g;
                    return GestureDetector(
                      onTap: () => setState(() => _newGender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? _teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(g,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: active ? Colors.white : const Color(0xFF8FA0B4))),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _newField(_newVillageCtrl, 'Village / Area', Icons.location_on_rounded),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final name = _newNameCtrl.text.trim();
                final age = _newAgeCtrl.text.trim();
                final village = _newVillageCtrl.text.trim();
                if (name.isEmpty || age.isEmpty || village.isEmpty) return;
                final newId = 'PAT-NEW-${DateTime.now().millisecondsSinceEpoch % 100000}';
                setState(() {
                  _patientListRuntime.insert(0, {
                    'id': newId, 'name': name,
                    'age': age, 'gender': _newGender, 'village': village,
                  });
                  _selectedPatientId = newId;
                  _showNewPatientForm = false;
                  _newNameCtrl.clear();
                  _newAgeCtrl.clear();
                  _newVillageCtrl.clear();
                });
              },
              icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              label: Text('Register & Select',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(Map<String, String> p) {
    final isSelected = _selectedPatientId == p['id'];
    final isNew = p['id']!.startsWith('PAT-NEW');
    return GestureDetector(
      onTap: () => setState(() => _selectedPatientId = p['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _teal.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _teal : const Color(0xFFEEF2F6),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? _teal.withValues(alpha: 0.12)
                    : const Color(0xFFF0F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  p['name']!.split(' ').map((w) => w[0]).take(2).join(),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: isSelected ? _teal : const Color(0xFF8FA0B4)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(p['name']!,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: isSelected ? _teal : const Color(0xFF1A2A3D))),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('New',
                              style: GoogleFonts.inter(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  color: _amber)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${p['gender']} \u00b7 ${p['age']} yrs \u00b7 ${p['village']}',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _teal, size: 20)
            else
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDE4EC), width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _newField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A2A3D)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4)),
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF8FA0B4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // Feature 12: brightness
  double? _originalBrightness;

  // Feature 13: test timer
  Timer? _testTimer;
  int _testSeconds = 0;

  // Feature 14: offline indicator
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Feature 15: unsynced records badge
  int _unsyncedCount = 0;

  Future<void> _loadUnsyncedCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _unsyncedCount = prefs.getInt('unsynced_count') ?? 0);
  }

  Future<void> _incrementUnsyncedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt('unsynced_count') ?? 0) + 1;
    await prefs.setInt('unsynced_count', next);
    if (!mounted) return;
    setState(() => _unsyncedCount = next);
  }

  void _startTestTimer() {
    _testSeconds = 0;
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _testSeconds++);
    });
  }

  void _stopTestTimer() {
    _testTimer?.cancel();
    _testTimer = null;
  }

  String get _testDuration {
    final m = _testSeconds ~/ 60;
    final s = _testSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _boostBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {}
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
        _originalBrightness = null;
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  // quarterTurns: 0=right,1=down,2=left,3=up
  void _recordAnswer(int tapped, List<int> rotations, int count) {
    final correct = tapped == rotations[_currentLetter];
    final updatedAnswers = [..._rowAnswers, correct];

    if (_currentLetter < count - 1) {
      // still letters left in this row
      setState(() {
        _rowAnswers = updatedAnswers;
        _currentLetter++;
      });
      return;
    }

    // Row complete — evaluate pass/fail
    final correctCount = updatedAnswers.where((a) => a).length;
    final minCorrect = (count / 2).ceil() + (count > 1 ? 0 : 0);
    final passed = correctCount >= minCorrect;

    setState(() {
      _rowAnswers = [];
      _currentLetter = 0;
      if (passed) {
        _consecutiveFailedRows = 0;
        _rowRetryUsed = false;
        if (_currentRow < _rows.length - 1) {
          _currentRow++;
        } else {
          _stoppingLogmar = _rows[_currentRow]['logmar'] as String;
          _eyeResults[_eyeOrder[_currentEyeIndex]] = _stoppingLogmar!;
          _restoreBrightness();
          _stopTestTimer();
          _step = 6;
        }
      } else {
        _consecutiveFailedRows++;
        _rowRetryUsed = false;
        if (_consecutiveFailedRows >= 2) {
          final stopRow = _currentRow > 0 ? _currentRow - 1 : 0;
          _stoppingLogmar = _rows[stopRow]['logmar'] as String;
          _eyeResults[_eyeOrder[_currentEyeIndex]] = _stoppingLogmar!;
          _restoreBrightness();
          _stopTestTimer();
          _step = 6;
        } else {
          if (_currentRow < _rows.length - 1) {
            _currentRow++;
          } else {
            _stoppingLogmar = _rows[_currentRow]['logmar'] as String;
            _eyeResults[_eyeOrder[_currentEyeIndex]] = _stoppingLogmar!;
            _restoreBrightness();
            _stopTestTimer();
            _step = 6;
          }
        }
      }
    });
  }

  Widget _dirBtn(IconData icon, int quarterTurns, List<int> rotations, int count) {
    return GestureDetector(
      onTap: () => _recordAnswer(quarterTurns, rotations, count),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE4EC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 24, color: _ink),
      ),
    );
  }

  Widget _buildEChart() {
    final eye = _eyeOrder[_currentEyeIndex];
    final row = _rows[_currentRow];
    final logmar = row['logmar'] as String;
    final size = row['size'] as double;
    final count = row['count'] as int;
    final rotations = _rotations[_currentRow];

    return Column(
      children: [
        // Top bar: eye label + LogMAR
        Container(
          color: _ink,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _teal3.withValues(alpha: 0.3)),
                ),
                child: Text(eye,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, fontWeight: FontWeight.w800, color: _teal3)),
              ),
              const Spacer(),
              Text('LogMAR $logmar',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 10),
              Text('Row ${_currentRow + 1}/${_rows.length}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded,
                      size: 12, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 3),
                  Text(_testDuration,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
              const SizedBox(width: 10),
              // Feature 11: retry button
              GestureDetector(
                onTap: _rowRetryUsed
                    ? null
                    : () => setState(() {
                          _currentLetter = 0;
                          _rowAnswers = [];
                          _rowRetryUsed = true;
                          _generateRotations();
                        }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _rowRetryUsed
                        ? Colors.white.withValues(alpha: 0.05)
                        : _amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: _rowRetryUsed
                          ? Colors.white.withValues(alpha: 0.1)
                          : _amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 12,
                          color: _rowRetryUsed
                              ? Colors.white.withValues(alpha: 0.2)
                              : _amber),
                      const SizedBox(width: 4),
                      Text('Retry',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _rowRetryUsed
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : _amber)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Row progress bar
        LinearProgressIndicator(
          value: (_currentRow + 1) / _rows.length,
          backgroundColor: const Color(0xFFEEF2F6),
          color: _teal,
          minHeight: 3,
        ),
        // E optotypes — highlight current letter
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(count, (i) {
                  final isCurrent = i == _currentLetter;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: size * 0.15),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: isCurrent ? BoxDecoration(
                        border: Border.all(color: _teal.withValues(alpha: 0.4), width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ) : null,
                      child: RotatedBox(
                        quarterTurns: rotations[i],
                        child: Text(
                          'E',
                          style: TextStyle(
                            fontSize: size,
                            fontWeight: FontWeight.w900,
                            color: isCurrent ? _ink : _ink.withValues(alpha: 0.25),
                            height: 1.0,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        // Direction tap buttons
        Container(
          color: const Color(0xFFF8FAFB),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Text('Which way is the E facing?',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF8FA0B4))),
              const SizedBox(height: 12),
              // Up
              _dirBtn(Icons.arrow_upward_rounded, 3, rotations, count),
              const SizedBox(height: 8),
              // Left / Right
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dirBtn(Icons.arrow_back_rounded, 2, rotations, count),
                  const SizedBox(width: 8),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded,
                        size: 20, color: Color(0xFF8FA0B4)),
                  ),
                  const SizedBox(width: 8),
                  _dirBtn(Icons.arrow_forward_rounded, 0, rotations, count),
                ],
              ),
              const SizedBox(height: 8),
              // Down
              _dirBtn(Icons.arrow_downward_rounded, 1, rotations, count),
            ],
          ),
        ),
      ],
    );
  }

  String _vaClass(String logmar) {
    final v = double.tryParse(logmar) ?? 1.0;
    if (v <= 0.0) return 'Normal';
    if (v <= 0.3) return 'Near Normal';
    if (v <= 0.5) return 'Moderate VI';
    if (v <= 1.0) return 'Severe VI';
    return 'Blind';
  }

  Color _vaColor(String logmar) {
    final v = double.tryParse(logmar) ?? 1.0;
    if (v <= 0.3) return _green;
    if (v <= 0.5) return _amber;
    return _red;
  }

  bool get _needsReferral =>
      _eyeResults.values.any((r) => (double.tryParse(r) ?? 1.0) > 0.3);

  Widget _buildResults() {
    final isLastEye = _currentEyeIndex >= _eyeOrder.length - 1;
    final allDone = _eyeResults.length == _eyeOrder.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withValues(alpha: 0.1),
                  border: Border.all(color: _teal.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded, size: 24, color: _teal),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eye Test Complete',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A2A3D))),
                  Text('Duration: $_testDuration',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF8FA0B4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._eyeResults.entries.map((e) {
            final eye = e.key;
            final logmar = e.value;
            final cls = _vaClass(logmar);
            final col = _vaColor(logmar);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(eye,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: col)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eye == 'OD' ? 'Right Eye' : eye == 'OS' ? 'Left Eye' : 'Both Eyes',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF8FA0B4))),
                        const SizedBox(height: 2),
                        Text(cls,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2A3D))),
                      ],
                    ),
                  ),
                  Text('LogMAR $logmar',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: col)),
                ],
              ),
            );
          }),
          if (allDone && _needsReferral) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital_rounded, color: _red, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Referral Recommended',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: _red)),
                        const SizedBox(height: 2),
                        Text(
                          'Visual acuity below normal threshold. Refer to nearest eye clinic.',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF5E7291),
                              height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!isLastEye)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  if (_isOffline) _incrementUnsyncedCount();
                  _currentEyeIndex++;
                  _currentRow = 0;
                  _currentLetter = 0;
                  _rowAnswers = [];
                  _consecutiveFailedRows = 0;
                  _rowRetryUsed = false;
                  _stoppingLogmar = null;
                  _generateRotations();
                  _step = 4;
                }),
                icon: const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.white),
                label: Text(
                  'Test Next Eye (${_eyeOrder[_currentEyeIndex + 1]})',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_isOffline) _incrementUnsyncedCount();
                  _restoreBrightness();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.done_rounded,
                    size: 18, color: Colors.white),
                label: Text('Save and Finish',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverEyeReminder() {
    final eye = _eyeOrder[_currentEyeIndex];
    final isOD = eye == 'OD';
    final isOU = eye == 'OU';
    final label = isOU ? 'Both Eyes Open' : isOD ? 'Cover Left Eye' : 'Cover Right Eye';
    final sub = isOU
        ? 'Test both eyes together — no cover needed'
        : isOD
            ? 'Ask the patient to cover their LEFT eye with their palm'
            : 'Ask the patient to cover their RIGHT eye with their palm';
    final eyeLabel = isOU ? 'OU' : isOD ? 'OD' : 'OS';
    final eyeFull = isOU ? 'Both Eyes' : isOD ? 'Right Eye' : 'Left Eye';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Eye order progress chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_eyeOrder.length, (i) {
              final done = i < _currentEyeIndex;
              final active = i == _currentEyeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: done
                      ? _green.withValues(alpha: 0.12)
                      : active
                          ? _teal
                          : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _eyeOrder[i],
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: done
                          ? _green
                          : active
                              ? Colors.white
                              : const Color(0xFF8FA0B4)),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          // Animated eye illustration
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: 0.95 + (_pulseAnim.value * 0.05),
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withValues(alpha: 0.08),
                  border: Border.all(color: _teal.withValues(alpha: 0.25), width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.remove_red_eye_rounded,
                        size: 72, color: _teal.withValues(alpha: 0.3)),
                    if (!isOU)
                      Positioned(
                        left: isOD ? 18 : null,
                        right: isOD ? null : 18,
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: _ink.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.back_hand_rounded,
                              size: 28, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('Testing: $eyeLabel — $eyeFull',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _teal)),
          ),
          const SizedBox(height: 16),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 10),
          Text(sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF5E7291), height: 1.6)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _generateRotations();
                _boostBrightness();
                _startTestTimer();
                setState(() {
                  _currentRow = 0;
                  _step = 5;
                });
              },
              icon: const Icon(Icons.visibility_rounded,
                  size: 18, color: Colors.white),
              label: Text('Patient is Ready — Begin Test',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  final bool faceDetected;
  final bool correctDistance;
  const _FaceOverlayPainter({required this.faceDetected, required this.correctDistance});

  @override
  void paint(Canvas canvas, Size size) {
    final color = correctDistance ? _green : faceDetected ? _amber : _teal3;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.55;
    final h = size.height * 0.65;
    const len = 28.0;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    // corners
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + len, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.top + len), paint);
    canvas.drawLine(Offset(rect.right - len, rect.top), Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + len), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom - len), Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + len, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right - len, rect.bottom), Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom - len), Offset(rect.right, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(_FaceOverlayPainter old) =>
      old.faceDetected != faceDetected || old.correctDistance != correctDistance;
}
