import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'referral_letter_screen.dart';

// ── Colours ──────────────────────────────────────────────────────────────────
const _ink  = Color(0xFF04091A);
const _ink2 = Color(0xFF0B1530);
const _teal = Color(0xFF0D9488);
const _teal3 = Color(0xFF5EEAD4);
const _amber = Color(0xFFF59E0B);
const _red   = Color(0xFFEF4444);
const _green = Color(0xFF22C55E);
const double _kMinLux = 80.0;

// ── Steps ─────────────────────────────────────────────────────────────────────
// 0=patient, 1=checklist, 2=coverEye, 3=chart, 4=eyeResult, 5=summary
// ── Eye order ─────────────────────────────────────────────────────────────────
const _eyeOrder = ['OD', 'OS', 'OU'];

// ── LogMAR rows (single E per row) ───────────────────────────────────────────
const _rows = [
  {'logmar': '1.0', 'size': 96.0},
  {'logmar': '0.9', 'size': 82.0},
  {'logmar': '0.8', 'size': 70.0},
  {'logmar': '0.7', 'size': 59.0},
  {'logmar': '0.6', 'size': 50.0},
  {'logmar': '0.5', 'size': 42.0},
  {'logmar': '0.4', 'size': 36.0},
  {'logmar': '0.3', 'size': 30.0},
  {'logmar': '0.2', 'size': 25.0},
  {'logmar': '0.1', 'size': 21.0},
  {'logmar': '0.0', 'size': 18.0},
];

class NewScreeningScreen extends StatefulWidget {
  const NewScreeningScreen({super.key});
  @override
  State<NewScreeningScreen> createState() => _NewScreeningScreenState();
}

class _NewScreeningScreenState extends State<NewScreeningScreen>
    with TickerProviderStateMixin {

  // ── Step ──────────────────────────────────────────────────────────────────
  int _step = 0;

  // ── Feature: Patient ──────────────────────────────────────────────────────
  String? _selectedPatientId;
  final _patientSearchCtrl = TextEditingController();
  String _patientQuery = '';
  bool _showNewPatientForm = false;
  final _newNameCtrl    = TextEditingController();
  final _newAgeCtrl     = TextEditingController();
  final _newVillageCtrl = TextEditingController();
  String _newGender = 'M';
  List<Map<String, String>> _patientListRuntime = _staticPatients
      .map((p) => Map<String, String>.from(p))
      .toList();

  static const _staticPatients = [
    {'id': 'PAT-00312', 'name': 'Akello Mercy',    'age': '34', 'gender': 'F', 'village': 'Nakawa, Kampala'},
    {'id': 'PAT-00298', 'name': 'Okello James',    'age': '58', 'gender': 'M', 'village': 'Bwaise, Kampala'},
    {'id': 'PAT-00301', 'name': 'Nakato Aisha',    'age': '27', 'gender': 'F', 'village': 'Ntinda, Kampala'},
    {'id': 'PAT-00315', 'name': 'Mugisha Wilson',  'age': '45', 'gender': 'M', 'village': 'Kireka, Wakiso'},
    {'id': 'PAT-00289', 'name': 'Kyomuhendo Rose', 'age': '19', 'gender': 'F', 'village': 'Rubaga, Kampala'},
    {'id': 'PAT-00276', 'name': 'Byaruhanga Sam',  'age': '62', 'gender': 'M', 'village': 'Kawempe, Kampala'},
    {'id': 'PAT-00261', 'name': 'Tendo Kevin',     'age': '9',  'gender': 'M', 'village': 'Nansana, Wakiso'},
    {'id': 'PAT-00254', 'name': 'Apio Norah',      'age': '8',  'gender': 'F', 'village': 'Kira, Wakiso'},
  ];

  // ── Feature: Checklist ────────────────────────────────────────────────────
  // light
  double _currentLux = 0.0;
  bool _luxChecked = false;
  bool _luxOk = false;
  // brightness
  bool _brightnessSet = false;
  double? _originalBrightness;
  // camera / face
  CameraController? _cameraCtrl;
  bool _cameraReady = false;
  bool _faceDetected = false;
  bool _faceAtDistance = false;
  Timer? _faceSimTimer;
  // captured photo path (simulated)
  String? _capturedPhotoPath;

  bool get _checklistDone => _luxOk && _brightnessSet && _faceAtDistance;

  // ── Feature: Eye test ─────────────────────────────────────────────────────
  int _currentEyeIndex = 0;
  int _currentRow = 0;
  int _currentRotation = 0;
  bool _rowRetryUsed = false;
  int _lastPassedRow = 0;
  final List<Map<String, dynamic>> _eyeResults = [];
  int _cantTellCount = 0;

  // ── Feature: Timer ────────────────────────────────────────────────────────
  Timer? _testTimer;
  int _testSeconds = 0;

  // ── Feature: Offline / unsynced ───────────────────────────────────────────
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int _unsyncedCount = 0;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadUnsyncedCount();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((r) {
      if (!mounted) return;
      setState(() => _isOffline = r.every((x) => x == ConnectivityResult.none));
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

  // ── Checklist logic ───────────────────────────────────────────────────────
  void _runChecklist() {
    _checkLight();
    _setMaxBrightness();
    _initCamera();
  }

  void _checkLight() {
    setState(() { _luxChecked = false; _luxOk = false; });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      const sim = 120.0;
      setState(() {
        _currentLux = sim;
        _luxChecked = true;
        _luxOk = sim >= _kMinLux;
      });
    });
  }

  Future<void> _setMaxBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
      if (mounted) setState(() => _brightnessSet = true);
    } catch (_) {
      if (mounted) setState(() => _brightnessSet = true);
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraCtrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cameraCtrl!.initialize();
    if (!mounted) return;
    setState(() => _cameraReady = true);
    _simulateFaceDetection();
  }

  void _simulateFaceDetection() {
    int tick = 0;
    _faceSimTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      tick++;
      setState(() {
        if (tick >= 2) _faceDetected = true;
        if (tick >= 4) {
          _faceAtDistance = true;
          _capturedPhotoPath = 'captured';
        }
      });
      if (_faceAtDistance) {
        _faceSimTimer?.cancel();
        // auto-advance once all 3 checks pass
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          if (_checklistDone) {
            _cameraCtrl?.dispose();
            _cameraCtrl = null;
            setState(() => _step = 2);
          }
        });
      }
    });
  }

  // ── Test logic ────────────────────────────────────────────────────────────
  void _generateRotation() {
    setState(() => _currentRotation = Random().nextInt(4));
  }

  void _startTestTimer() {
    _testSeconds = 0;
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _testSeconds++);
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

  void _recordResponse(bool correct) {
    setState(() {
      if (correct) _lastPassedRow = _currentRow;
      _rowRetryUsed = false;
      if (_currentRow < _rows.length - 1) {
        _currentRow++;
        _generateRotation();
      } else {
        _finishEye(_rows[_lastPassedRow]['logmar'] as String);
      }
    });
  }

  void _recordCantTell() {
    setState(() {
      _cantTellCount++;
      _rowRetryUsed = false;
      if (_currentRow < _rows.length - 1) {
        _currentRow++;
        _generateRotation();
      } else {
        _finishEye(_rows[_lastPassedRow]['logmar'] as String);
      }
    });
  }

  void _finishEye(String result) {
    _stopTestTimer();
    _restoreBrightness();
    setState(() {
      _eyeResults.add({
        'eye': _eyeOrder[_currentEyeIndex],
        'logmar': result,
        'duration': _testDuration,
        'cantTell': _cantTellCount,
      });
      _step = 4; // per-eye result
    });
  }

  void _nextEye() {
    setState(() {
      _currentEyeIndex++;
      _currentRow = 0;
      _lastPassedRow = 0;
      _rowRetryUsed = false;
      _cantTellCount = 0;
      _generateRotation();
      _step = 2; // cover eye reminder
    });
  }

  void _goToSummary() => setState(() => _step = 5);

  // ── Unsynced ──────────────────────────────────────────────────────────────
  Future<void> _loadUnsyncedCount() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _unsyncedCount = p.getInt('unsynced_count') ?? 0);
  }

  Future<void> _incrementUnsynced() async {
    final p = await SharedPreferences.getInstance();
    final n = (p.getInt('unsynced_count') ?? 0) + 1;
    await p.setInt('unsynced_count', n);
    if (mounted) setState(() => _unsyncedCount = n);
  }

  // ── VA helpers ────────────────────────────────────────────────────────────
  String _toSnellen(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return logmar;
    const snaps = [6, 9, 12, 18, 24, 36, 48, 60, 120];
    final second = (6 * pow(10, v)).round();
    return '6/${snaps.reduce((a, b) => (a - second).abs() < (b - second).abs() ? a : b)}';
  }

  String _vaClass(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return logmar; // LV level string
    if (v <= 0.0) return 'Normal';
    if (v <= 0.3) return 'Near Normal';
    if (v <= 0.5) return 'Moderate VI';
    if (v <= 1.0) return 'Severe VI';
    return 'Blind';
  }

  Color _vaColor(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return _red;
    if (v <= 0.3) return _green;
    if (v <= 0.5) return _amber;
    return _red;
  }

  double _blurSigma(String logmar) {
    final v = double.tryParse(logmar);
    if (v == null) return 18.0;
    if (v <= 0.0) return 0.0;
    if (v <= 0.3) return 1.5;
    if (v <= 0.5) return 4.0;
    if (v <= 1.0) return 9.0;
    return 18.0;
  }

  bool get _needsReferral => _eyeResults.any((r) {
    final v = double.tryParse(r['logmar'] as String);
    return v == null || v > 0.3;
  });

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          if (_isOffline) _offlineBanner(),
          Expanded(child: _buildStep()),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildPatientSelector();
      case 1: return _buildChecklist();
      case 2: return _buildCoverEyeReminder();
      case 3: return _buildEChart();
      case 4: return _buildEyeResult();
      case 5: return _buildSummary();
      default: return const SizedBox();
    }
  }

  Widget _offlineBanner() => Container(
    width: double.infinity,
    color: _amber.withValues(alpha: 0.12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.wifi_off_rounded, size: 14, color: _amber),
        const SizedBox(width: 8),
        Text('No internet — results will be saved locally',
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: _amber)),
      ],
    ),
  );

  // ── Header ────────────────────────────────────────────────────────────────
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
                onTap: () {
                  _restoreBrightness();
                  Navigator.pop(context);
                },
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
                              fontSize: 10, fontWeight: FontWeight.w700, color: _amber)),
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

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _stepBar(int current) {
    const total = 6;
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: i < current ? _teal : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 4),
          ],
        ),
      )),
    );
  }

  // ── Step 0: Patient Selector ─────────────────────────────────────────────
  Widget _buildPatientSelector() {
    final filtered = _patientListRuntime.where((p) {
      if (_patientQuery.isEmpty) return true;
      final q = _patientQuery.toLowerCase();
      return p['name']!.toLowerCase().contains(q) ||
          p['id']!.toLowerCase().contains(q) ||
          p['village']!.toLowerCase().contains(q);
    }).toList();

    if (_showNewPatientForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepBar(1),
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
              _continueBtn('Continue to Setup', () {
                setState(() => _step = 1);
                _runChecklist();
              }),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepBar(1),
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
              ? Center(child: Text('No patients found',
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
            child: _continueBtn('Continue to Setup', () {
              setState(() => _step = 1);
              _runChecklist();
            }),
          ),
      ],
    );
  }

  Widget _searchBar() => Container(
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

  Widget _newPatientToggle() => GestureDetector(
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
          Icon(_showNewPatientForm
              ? Icons.remove_circle_outline_rounded
              : Icons.person_add_rounded, size: 18, color: _teal),
          const SizedBox(width: 10),
          Text(_showNewPatientForm ? 'Cancel new patient' : 'Add new patient',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _teal)),
        ],
      ),
    ),
  );

  Widget _newPatientForm() => Container(
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
            Expanded(child: _newField(_newAgeCtrl, 'Age', Icons.cake_rounded,
                inputType: TextInputType.number)),
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
              final age  = _newAgeCtrl.text.trim();
              final vil  = _newVillageCtrl.text.trim();
              if (name.isEmpty || age.isEmpty || vil.isEmpty) return;
              final id = 'PAT-NEW-${DateTime.now().millisecondsSinceEpoch % 100000}';
              setState(() {
                _patientListRuntime.insert(0, {
                  'id': id, 'name': name, 'age': age,
                  'gender': _newGender, 'village': vil,
                });
                _selectedPatientId = id;
                _showNewPatientForm = false;
                _newNameCtrl.clear(); _newAgeCtrl.clear(); _newVillageCtrl.clear();
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
                color: isSelected ? _teal.withValues(alpha: 0.12) : const Color(0xFFF0F4F7),
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
                  Row(children: [
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
                                fontSize: 9, fontWeight: FontWeight.w700, color: _amber)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text('${p['gender']} · ${p['age']} yrs · ${p['village']}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
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
      {TextInputType inputType = TextInputType.text}) =>
    Container(
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

  // ── Shared continue button ────────────────────────────────────────────────
  Widget _continueBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
      label: Text(label,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
  );

  // PLACEHOLDERS
  Widget _buildChecklist() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(2),
          const SizedBox(height: 28),
          Text('Environment & Setup',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 6),
          Text('Three checks run automatically. All must pass before testing.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5E7291))),
          const SizedBox(height: 28),
          // ── Check 1: Ambient light ──────────────────────────────────────
          _checkTile(
            icon: Icons.wb_sunny_rounded,
            title: 'Ambient Light',
            subtitle: _luxChecked
                ? (_luxOk
                    ? '${_currentLux.toStringAsFixed(0)} lux — meets WHO threshold'
                    : '${_currentLux.toStringAsFixed(0)} lux — too low (min ${_kMinLux.toInt()} lux)')
                : 'Measuring ambient light...',
            state: _luxChecked ? (_luxOk ? _CheckState.pass : _CheckState.fail) : _CheckState.loading,
          ),
          if (_luxChecked && !_luxOk) ...[  
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Improve lighting before proceeding:',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D))),
                  const SizedBox(height: 6),
                  ...[
                    'Move to a room with natural daylight',
                    'Turn on all available lights',
                    'Ensure patient faces the light source',
                  ].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 4, height: 4,
                          decoration: const BoxDecoration(
                              color: _red, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF5E7291)))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _checkLight,
                      icon: const Icon(Icons.refresh_rounded, size: 14, color: _teal),
                      label: Text('Re-check Lighting',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _teal),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          // ── Check 2: Screen brightness ──────────────────────────────────
          _checkTile(
            icon: Icons.brightness_high_rounded,
            title: 'Screen Brightness',
            subtitle: _brightnessSet
                ? 'Set to 100% automatically'
                : 'Setting screen brightness...',
            state: _brightnessSet ? _CheckState.pass : _CheckState.loading,
          ),
          const SizedBox(height: 14),
          // ── Check 3: Face detection ─────────────────────────────────────
          _checkTile(
            icon: Icons.face_rounded,
            title: 'Face Detection at 3 Metres',
            subtitle: _faceAtDistance
                ? 'Patient detected — photo captured'
                : _faceDetected
                    ? 'Face found — confirming distance...'
                    : _cameraReady
                        ? 'Looking for patient face...'
                        : 'Initialising camera...',
            state: _faceAtDistance
                ? _CheckState.pass
                : _CheckState.loading,
          ),
          if (_cameraReady && _cameraCtrl != null) ...[  
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 320, width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_cameraCtrl!),
                    CustomPaint(
                      painter: _FaceOverlayPainter(
                        faceDetected: _faceDetected,
                        correctDistance: _faceAtDistance,
                      ),
                    ),
                    if (_faceAtDistance)
                      Positioned(
                        bottom: 10, left: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text('Distance confirmed — photo captured',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          AnimatedOpacity(
            opacity: _checklistDone ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: _green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All checks passed',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: _green)),
                        Text('Proceeding to eye test automatically...',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF5E7291))),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required _CheckState state,
  }) {
    final color = state == _CheckState.pass
        ? _green
        : state == _CheckState.fail
            ? _red
            : _amber;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state == _CheckState.pass
              ? _green.withValues(alpha: 0.3)
              : state == _CheckState.fail
                  ? _red.withValues(alpha: 0.3)
                  : const Color(0xFFEEF2F6),
          width: 1.5,
        ),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2A3D))),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF5E7291))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (state == _CheckState.loading)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
            )
          else
            Icon(
              state == _CheckState.pass
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: color, size: 22,
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
    final eyeFull  = isOU ? 'Both Eyes' : isOD ? 'Right Eye' : 'Left Eye';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _stepBar(3),
          const SizedBox(height: 24),
          // Eye order chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_eyeOrder.length, (i) {
              final done   = i < _currentEyeIndex;
              final active = i == _currentEyeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: done ? _green.withValues(alpha: 0.12)
                      : active ? _teal : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(_eyeOrder[i],
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: done ? _green
                            : active ? Colors.white
                            : const Color(0xFF8FA0B4))),
              );
            }),
          ),
          const SizedBox(height: 32),
          // Animated eye illustration
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
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
                        left: isOD ? 16 : null,
                        right: isOD ? null : 16,
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
          _continueBtn('Patient is Ready — Begin Test', () {
            _generateRotation();
            _startTestTimer();
            setState(() => _step = 3);
          }),
        ],
      ),
    );
  }
  Widget _buildEChart() {
    final eye    = _eyeOrder[_currentEyeIndex];
    final row    = _rows[_currentRow];
    final logmar = row['logmar'] as String;
    final size   = row['size'] as double;

    // ── Normal chart ─────────────────────────────────────────────────────
    return Column(
      children: [
        // Top bar
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
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded,
                      size: 12, color: Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 3),
                  Text(_testDuration,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
              const SizedBox(width: 10),
              // Retry button
              GestureDetector(
                onTap: _rowRetryUsed ? null : () => setState(() {
                  _rowRetryUsed = true;
                  _generateRotation();
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
                      Icon(Icons.refresh_rounded, size: 12,
                          color: _rowRetryUsed
                              ? Colors.white.withValues(alpha: 0.2) : _amber),
                      const SizedBox(width: 4),
                      Text('Retry',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: _rowRetryUsed
                                  ? Colors.white.withValues(alpha: 0.2) : _amber)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Row progress
        LinearProgressIndicator(
          value: (_currentRow + 1) / _rows.length,
          backgroundColor: const Color(0xFFEEF2F6),
          color: _teal, minHeight: 3,
        ),
        // Single E display
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: RotatedBox(
                quarterTurns: _currentRotation,
                child: Text('E',
                    style: TextStyle(
                      fontSize: size,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      height: 1.0,
                      fontFamily: 'Courier',
                    )),
              ),
            ),
          ),
        ),
        // Direction buttons + Can't Tell
        Container(
          color: const Color(0xFFF8FAFB),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Text('Which way is the E facing?',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF8FA0B4))),
              const SizedBox(height: 14),
              // Up
              _dirBtn(Icons.arrow_upward_rounded, 3),
              const SizedBox(height: 10),
              // Left / Eye / Right
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dirBtn(Icons.arrow_back_rounded, 2),
                  const SizedBox(width: 10),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded,
                        size: 22, color: Color(0xFF8FA0B4)),
                  ),
                  const SizedBox(width: 10),
                  _dirBtn(Icons.arrow_forward_rounded, 0),
                ],
              ),
              const SizedBox(height: 10),
              // Down
              _dirBtn(Icons.arrow_downward_rounded, 1),
              const SizedBox(height: 14),
              // Can't Tell
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _recordCantTell,
                  icon: const Icon(Icons.help_outline_rounded,
                      size: 18, color: Color(0xFF8FA0B4)),
                  label: Text("Can't Tell",
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: const Color(0xFF5E7291))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFDDE4EC), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dirBtn(IconData icon, int quarterTurns) {
    return GestureDetector(
      onTap: () => _recordResponse(quarterTurns == _currentRotation),
      child: Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE4EC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 28, color: _ink),
      ),
    );
  }
  Widget _buildEyeResult() {
    if (_eyeResults.isEmpty) return const SizedBox();
    final r       = _eyeResults.last;
    final eye     = r['eye'] as String;
    final logmar  = r['logmar'] as String;
    final dur     = r['duration'] as String;
    final cantTel = r['cantTell'] as int;
    final cls     = _vaClass(logmar);
    final col     = _vaColor(logmar);
    final isLastEye = _currentEyeIndex >= _eyeOrder.length - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(4),
          const SizedBox(height: 24),
          // Eye chip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_eyeOrder.length, (i) {
              final done   = i <= _currentEyeIndex;
              final active = i == _currentEyeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: done ? _green.withValues(alpha: 0.12)
                      : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(99),
                  border: active ? Border.all(color: _green, width: 1.5) : null,
                ),
                child: Text(_eyeOrder[i],
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: done ? _green : const Color(0xFF8FA0B4))),
              );
            }),
          ),
          const SizedBox(height: 28),
          // Result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: col.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: col.withValues(alpha: 0.1),
                  blurRadius: 20, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: col.withValues(alpha: 0.1),
                    border: Border.all(color: col.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(eye,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w800, color: col)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  eye == 'OD' ? 'Right Eye' : eye == 'OS' ? 'Left Eye' : 'Both Eyes',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF8FA0B4))),
                const SizedBox(height: 6),
                Text(
                  double.tryParse(logmar) != null ? _toSnellen(logmar) : logmar,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 48, fontWeight: FontWeight.w900, color: col)),
                if (double.tryParse(logmar) != null)
                  Text('LogMAR $logmar',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: col.withValues(alpha: 0.7))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(cls,
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700, color: col)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip(Icons.timer_rounded, dur, 'Duration'),
                    const SizedBox(width: 12),
                    _statChip(Icons.help_outline_rounded,
                        '$cantTel', "Can't Tell"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Blur simulation
          _blurPreview(logmar),
          const SizedBox(height: 28),
          if (!isLastEye)
            _continueBtn(
              'Test Next Eye (${_eyeOrder[_currentEyeIndex + 1]})',
              _nextEye,
            )
          else
            _continueBtn('View Full Summary', _goToSummary),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8FA0B4)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF8FA0B4))),
        ],
      ),
    );
  }

  Widget _blurPreview(String logmar) {
    final sigma = _blurSigma(logmar);
    final cls   = _vaClass(logmar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visual Simulation',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2A3D))),
        const SizedBox(height: 4),
        Text('Approximate view at this acuity level',
            style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF8FA0B4))),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                color: Colors.white,
                child: Center(
                  child: sigma == 0
                      ? Text('E',
                          style: TextStyle(
                              fontSize: 64, fontWeight: FontWeight.w900,
                              color: _ink, fontFamily: 'Courier'))
                      : ImageFiltered(
                          imageFilter: ColorFilter.matrix([
                            1, 0, 0, 0, 0,
                            0, 1, 0, 0, 0,
                            0, 0, 1, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                          child: ImageFiltered(
                            imageFilter: _blurFilter(sigma),
                            child: Text('E',
                                style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                    fontFamily: 'Courier')),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cls,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Use ColorFilter as blur approximation (no dart:ui ImageFilter needed)
  ColorFilter _blurFilter(double sigma) {
    // Darken + desaturate proportional to blur level as visual proxy
    final f = (sigma / 18.0).clamp(0.0, 1.0);
    return ColorFilter.matrix([
      1 - f * 0.3, 0, 0, 0, f * 30,
      0, 1 - f * 0.3, 0, 0, f * 30,
      0, 0, 1 - f * 0.3, 0, f * 30,
      0, 0, 0, 1 - f * 0.5, 0,
    ]);
  }
  Widget _buildSummary() {
    final patient = _patientListRuntime
        .where((p) => p['id'] == _selectedPatientId)
        .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(6),
          const SizedBox(height: 24),
          // Patient banner
          if (patient != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        patient['name']!.split(' ').map((w) => w[0]).take(2).join(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w800, color: _teal3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient['name']!,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(
                          '${patient['gender']} · ${patient['age']} yrs · ${patient['village']}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  if (_isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Offline',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: _amber)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text('Screening Results',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 16),
          // Per-eye result cards
          ..._eyeResults.map((r) {
            final eye    = r['eye'] as String;
            final logmar = r['logmar'] as String;
            final dur    = r['duration'] as String;
            final ct     = r['cantTell'] as int;
            final cls    = _vaClass(logmar);
            final col    = _vaColor(logmar);
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
                              fontSize: 13, fontWeight: FontWeight.w800, color: col)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eye == 'OD' ? 'Right Eye'
                              : eye == 'OS' ? 'Left Eye' : 'Both Eyes',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF8FA0B4))),
                        const SizedBox(height: 2),
                        Text(cls,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2A3D))),
                        if (ct > 0)
                          Text("$ct can't tell response${ct > 1 ? 's' : ''}",
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: _amber)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        double.tryParse(logmar) != null
                            ? _toSnellen(logmar) : logmar,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w800, color: col)),
                      if (double.tryParse(logmar) != null)
                        Text('LogMAR $logmar',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: col.withValues(alpha: 0.7))),
                      Text(dur,
                          style: GoogleFonts.inter(
                              fontSize: 10, color: const Color(0xFF8FA0B4))),
                    ],
                  ),
                ],
              ),
            );
          }),
          // Referral banner
          if (_needsReferral) ...[
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
                          'Vision below 6/12 in one or more eyes. '
                          'Refer to nearest eye clinic.',
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
          const SizedBox(height: 28),
          if (_needsReferral)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final patient = _patientListRuntime
                        .where((p) => p['id'] == _selectedPatientId)
                        .firstOrNull;
                    if (patient == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReferralLetterScreen(
                          patient: patient,
                          eyeResults: _eyeResults,
                          screeningDate: DateTime.now()
                              .toString().substring(0, 10),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_rounded,
                      size: 18, color: Colors.white),
                  label: Text('Generate Referral Letter',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_isOffline) await _incrementUnsynced();
                _restoreBrightness();
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
              label: Text(
                _isOffline ? 'Save Locally & Finish' : 'Save & Finish',
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
          const SizedBox(height: 12),
          Center(
            child: Text(
              _isOffline
                  ? 'Will sync automatically when connection is restored'
                  : 'Results will be saved to the patient record',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF8FA0B4))),
          ),
        ],
      ),
    );
  }
}

enum _CheckState { loading, pass, fail }

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
    final h = size.height * 0.75;
    const len = 24.0;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
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
