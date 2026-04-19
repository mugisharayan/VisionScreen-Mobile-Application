import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
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
const _eyeOrder = ['OD', 'OS'];

// ── LogMAR rows (single E per row) ───────────────────────────────────────────
// ── Staircase levels (logmar index into _rows) ────────────────────────────────
// Initial jump sequence: 1.0 → 0.8 → 0.5 → 0.2 → 0.0 (indices 0,2,5,8,10)
const _staircaseJumps = [0, 2, 5, 8, 10];

// LogMAR rows — sizes in mm at 2m (formula: 29.1 × 10^(logmar-1.0))
// Source: Visual Acuity app measurements at 2m testing distance
const _rows = [
  {'logmar': '1.0', 'mm': 29.10},
  {'logmar': '0.9', 'mm': 23.12},
  {'logmar': '0.8', 'mm': 18.36},
  {'logmar': '0.7', 'mm': 14.59},
  {'logmar': '0.6', 'mm': 11.59},
  {'logmar': '0.5', 'mm':  9.21},
  {'logmar': '0.4', 'mm':  7.31},
  {'logmar': '0.3', 'mm':  5.81},
  {'logmar': '0.2', 'mm':  4.61},
  {'logmar': '0.1', 'mm':  3.66},
  {'logmar': '0.0', 'mm':  2.91},
];

// Convert mm to logical pixels using device DPI
// Uses dart:ui window.physicalSize and devicePixelRatio to derive actual physical DPI.
// physicalDpi = sqrt(physicalW² + physicalH²) / diagonalInches
// Since Flutter doesn't expose diagonalInches, we use the validated approximation
// physicalDpi = 160 × devicePixelRatio, which matches most Android/iOS devices.
// For clinical accuracy, the CHW should verify on a known-DPI device.
double _mmToPx(double mm, BuildContext context) {
  final mq = MediaQuery.of(context);
  final physicalW = mq.size.width * mq.devicePixelRatio;
  final physicalH = mq.size.height * mq.devicePixelRatio;
  // Derive physical DPI from screen diagonal physical pixels.
  // We assume a standard 5-inch diagonal as a baseline fallback.
  // diagonal physical pixels / diagonal inches = physical DPI
  // Without the actual diagonal inches from the OS, we use:
  // physicalDpi ≈ sqrt(physicalW² + physicalH²) / 5.0  (5" baseline)
  // This is more accurate than 160×dpr on non-standard screens.
  final diagonalPx = sqrt(physicalW * physicalW + physicalH * physicalH);
  // Use 5.5" as a representative modern smartphone diagonal
  const assumedDiagonalInches = 5.5;
  final physicalDpi = diagonalPx / assumedDiagonalInches;
  return (mm / 25.4) * (physicalDpi / mq.devicePixelRatio);
}

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
  final _newVillageCtrl = TextEditingController();
  String _newGender = 'M';
  DateTime? _newDob;
  bool _detectingLocation = false;
  final List<String> _newConditions = [];
  String? _newPhotoPath;
  CameraController? _photoCtrl;
  bool _showPhotoCamera = false;
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
  final int _selectedDistance = 2;
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
  int _currentRow = 0;       // index into _rows
  int _currentRotation = 0;
  int _lastPassedRow = 0;
  // Staircase state
  int _letterIndex = 0;       // 0-4, which of the 5 letters in current row
  int _correctCount = 0;      // correct answers in current row
  int _staircaseJumpIndex = 0; // where we are in _staircaseJumps
  bool _staircasePhase = true; // true=initial jumps, false=fine search
  int _fineSearchDir = 0;      // +1 going harder, -1 going easier
  final List<Map<String, dynamic>> _eyeResults = [];
  int _cantTellCount = 0;

  // Near vision (binocular, 40cm)
  int _nearRow = 0;
  int _nearLetterIndex = 0;
  int _nearCorrectCount = 0;
  int _nearLastPassedRow = 0;
  int _nearRotation = 0;
  bool _nearStaircasePhase = true;
  int _nearStaircaseJumpIndex = 0;
  int _nearCantTellCount = 0;
  Map<String, dynamic>? _nearResult;

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
    _recoverLostPhoto();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((r) {
      if (!mounted) return;
      setState(() => _isOffline = r.every((x) => x == ConnectivityResult.none));
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _cameraCtrl?.dispose();
    _photoCtrl?.dispose();
    _faceSimTimer?.cancel();
    _nearFaceSimTimer?.cancel();
    _testTimer?.cancel();
    _connectivitySub?.cancel();
    _patientSearchCtrl.dispose();
    _newNameCtrl.dispose();
    _newVillageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPhotoCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted || !mounted) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _photoCtrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _photoCtrl!.initialize();
    if (!mounted) return;
    setState(() => _showPhotoCamera = true);
  }

  Future<void> _takePhoto() async {
    if (_photoCtrl == null || !_photoCtrl!.value.isInitialized) return;
    try {
      final file = await _photoCtrl!.takePicture();
      final path = file.path;
      final ctrl = _photoCtrl;
      _photoCtrl = null;
      setState(() {
        _newPhotoPath = path;
        _showPhotoCamera = false;
      });
      await ctrl?.dispose();
    } catch (e) {
      final ctrl = _photoCtrl;
      _photoCtrl = null;
      if (mounted) setState(() => _showPhotoCamera = false);
      await ctrl?.dispose();
    }
  }

  void _closePhotoCamera() {
    final ctrl = _photoCtrl;
    _photoCtrl = null;
    if (mounted) setState(() => _showPhotoCamera = false);
    ctrl?.dispose();
  }

  Future<void> _recoverLostPhoto() async {}

  void _showPhotoOptions() => _openPhotoCamera();

  // ── Checklist logic ───────────────────────────────────────────────────────
  void _runChecklist() {
    _checkLight();
    _setMaxBrightness();
    _initCamera();
  }

  void _checkLight() {
    setState(() { _luxChecked = false; _luxOk = false; });
    const channel = EventChannel('visionscreen/light');
    StreamSubscription? sub;
    bool received = false;
    try {
      sub = channel.receiveBroadcastStream().listen(
        (dynamic lux) {
          if (received) return;
          received = true;
          sub?.cancel();
          if (!mounted) return;
          setState(() {
            _currentLux = (lux as double);
            _luxChecked = true;
            _luxOk = _currentLux >= _kMinLux;
          });
        },
        onError: (_) {
          if (received) return;
          received = true;
          sub?.cancel();
          if (!mounted) return;
          const fallback = 120.0;
          setState(() {
            _currentLux = fallback;
            _luxChecked = true;
            _luxOk = fallback >= _kMinLux;
          });
        },
      );
      // 3s timeout fallback for non-Android or unresponsive sensor
      Future.delayed(const Duration(seconds: 3), () {
        if (!received) {
          received = true;
          sub?.cancel();
          if (!mounted) return;
          const fallback = 120.0;
          setState(() {
            _currentLux = fallback;
            _luxChecked = true;
            _luxOk = fallback >= _kMinLux;
          });
        }
      });
    } catch (_) {
      const fallback = 120.0;
      setState(() {
        _currentLux = fallback;
        _luxChecked = true;
        _luxOk = fallback >= _kMinLux;
      });
    }
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
        // Poll every 200ms until lux and brightness are also confirmed
        _waitForAllChecks();
      }
    });
  }

  void _waitForAllChecks() {
    if (!mounted) return;
    if (_checklistDone) {
      _cameraCtrl?.dispose();
      _cameraCtrl = null;
      setState(() => _step = 2);
    } else {
      Future.delayed(const Duration(milliseconds: 200), _waitForAllChecks);
    }
  }

  // ── Near vision face detection ─────────────────────────────────────────
  bool _nearFaceDetected = false;
  bool _nearFaceAtDistance = false;
  Timer? _nearFaceSimTimer;

  Future<void> _initNearCamera() async {
    _nearFaceDetected = false;
    _nearFaceAtDistance = false;
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
    _simulateNearFaceDetection();
  }

  void _simulateNearFaceDetection() {
    int tick = 0;
    _nearFaceSimTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      tick++;
      setState(() {
        if (tick >= 2) _nearFaceDetected = true;
        if (tick >= 4) _nearFaceAtDistance = true;
      });
      if (_nearFaceAtDistance) {
        _nearFaceSimTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          _cameraCtrl?.dispose();
          _cameraCtrl = null;
          setState(() {
            _cameraReady = false;
            _step = 7;
          });
          _startTestTimer();
        });
      }
    });
  }

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
      if (correct) _correctCount++;
      _letterIndex++;

      if (_letterIndex < 5) {
        // still letters left in this row
        _generateRotation();
        return;
      }

      // Row of 5 complete — evaluate
      final passed = _correctCount >= 4;
      _letterIndex = 0;
      _correctCount = 0;

      if (passed) {
        _lastPassedRow = _currentRow;
        _advanceStaircase(passed: true);
      } else {
        _advanceStaircase(passed: false);
      }
    });
  }

  void _recordCantTell() {
    setState(() {
      _cantTellCount++;
      _letterIndex++;
      if (_letterIndex < 5) {
        _generateRotation();
        return;
      }
      // row complete — cant tell counts as fail
      final passed = _correctCount >= 4;
      _letterIndex = 0;
      _correctCount = 0;
      if (passed) {
        _lastPassedRow = _currentRow;
        _advanceStaircase(passed: true);
      } else {
        _advanceStaircase(passed: false);
      }
    });
  }

  void _advanceStaircase({required bool passed}) {
    if (_staircasePhase) {
      // ── Initial jump phase ──
      if (passed) {
        _staircaseJumpIndex++;
        if (_staircaseJumpIndex >= _staircaseJumps.length) {
          // reached finest level — done
          _finishEye(_rows[_lastPassedRow]['logmar'] as String);
          return;
        }
        _currentRow = _staircaseJumps[_staircaseJumpIndex];
      } else {
        // failed a jump level — switch to fine search going easier
        _staircasePhase = false;
        _fineSearchDir = -1;
        _currentRow = (_currentRow + 1).clamp(0, _rows.length - 1);
        if (_currentRow >= _rows.length - 1) {
          _finishEye(_rows[_lastPassedRow]['logmar'] as String);
          return;
        }
      }
    } else {
      // ── Fine search phase ──
      if (passed) {
        _lastPassedRow = _currentRow;
        // try one harder
        final next = _currentRow - 1;
        if (next < 0) {
          _finishEye(_rows[_lastPassedRow]['logmar'] as String);
          return;
        }
        _currentRow = next;
      } else {
        // failed — stop, last passed is the result
        _finishEye(_rows[_lastPassedRow]['logmar'] as String);
        return;
      }
    }
    _generateRotation();
  }

  void _finishEye(String result) {
    _stopTestTimer();
    _restoreBrightness();
    final isLastEye = _currentEyeIndex >= _eyeOrder.length - 1;
    setState(() {
      _eyeResults.add({
        'eye': _eyeOrder[_currentEyeIndex],
        'logmar': result,
        'duration': _testDuration,
        'cantTell': _cantTellCount,
      });
      if (isLastEye) {
        // all distance eyes done — go to near vision
        _nearRow = 0;
        _nearLetterIndex = 0;
        _nearCorrectCount = 0;
        _nearLastPassedRow = 0;
        _nearStaircasePhase = true;
        _nearStaircaseJumpIndex = 0;
        _nearCantTellCount = 0;
        _nearResult = null;
        _step = 6; // near vision intro
      } else {
        // more eyes to test — go straight to cover eye reminder
        _currentEyeIndex++;
        _currentRow = 0;
        _lastPassedRow = 0;
        _letterIndex = 0;
        _correctCount = 0;
        _staircaseJumpIndex = 0;
        _staircasePhase = true;
        _fineSearchDir = 0;
        _cantTellCount = 0;
        _generateRotation();
        _step = 2; // cover eye reminder
      }
    });
  }


















  void _goToSummary() {
    // after all distance eyes done, go to near vision
    setState(() {
      _nearRow = 0;
      _nearLetterIndex = 0;
      _nearCorrectCount = 0;
      _nearLastPassedRow = 0;
      _nearStaircasePhase = true;
      _nearStaircaseJumpIndex = 0;
      _nearCantTellCount = 0;
      _nearResult = null;
      _step = 6;
    });
    _generateNearRotation();
  }

  void _goToFinalSummary() => setState(() => _step = 5);

  void _generateNearRotation() =>
      setState(() => _nearRotation = Random().nextInt(4));

  void _recordNearResponse(bool correct) {
    setState(() {
      if (correct) _nearCorrectCount++;
      _nearLetterIndex++;
      if (_nearLetterIndex < 5) {
        _generateNearRotation();
        return;
      }
      final passed = _nearCorrectCount >= 4;
      _nearLetterIndex = 0;
      _nearCorrectCount = 0;
      if (passed) {
        _nearLastPassedRow = _nearRow;
        _advanceNearStaircase(passed: true);
      } else {
        _advanceNearStaircase(passed: false);
      }
    });
  }

  void _recordNearCantTell() {
    setState(() {
      _nearCantTellCount++;
      _nearLetterIndex++;
      if (_nearLetterIndex < 5) {
        _generateNearRotation();
        return;
      }
      final passed = _nearCorrectCount >= 4;
      _nearLetterIndex = 0;
      _nearCorrectCount = 0;
      _advanceNearStaircase(passed: passed);
    });
  }

  void _advanceNearStaircase({required bool passed}) {
    if (_nearStaircasePhase) {
      if (passed) {
        _nearStaircaseJumpIndex++;
        if (_nearStaircaseJumpIndex >= _staircaseJumps.length) {
          _finishNear(_rows[_nearLastPassedRow]['logmar'] as String);
          return;
        }
        _nearRow = _staircaseJumps[_nearStaircaseJumpIndex];
      } else {
        _nearStaircasePhase = false;
        _nearRow = (_nearRow + 1).clamp(0, _rows.length - 1);
        if (_nearRow >= _rows.length - 1) {
          _finishNear(_rows[_nearLastPassedRow]['logmar'] as String);
          return;
        }
      }
    } else {
      if (passed) {
        _nearLastPassedRow = _nearRow;
        final next = _nearRow - 1;
        if (next < 0) {
          _finishNear(_rows[_nearLastPassedRow]['logmar'] as String);
          return;
        }
        _nearRow = next;
      } else {
        _finishNear(_rows[_nearLastPassedRow]['logmar'] as String);
        return;
      }
    }
    _generateNearRotation();
  }

  void _finishNear(String logmar) {
    _stopTestTimer();
    setState(() {
      _nearResult = {
        'logmar': logmar,
        'duration': _testDuration,
        'cantTell': _nearCantTellCount,
      };
      _step = 5; // go straight to final summary
    });
  }

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

  bool get _needsReferral {
    final distancePoor = _eyeResults.any((r) {
      final v = double.tryParse(r['logmar'] as String);
      return v == null || v > 0.3;
    });
    final nearPoor = _nearResult != null &&
        (double.tryParse(_nearResult!['logmar'] as String) ?? 1.0) > 0.3;
    return distancePoor || nearPoor;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_showPhotoCamera && _photoCtrl != null && _photoCtrl!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_photoCtrl!),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: _closePhotoCamera,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
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
      case 6: return _buildNearVisionIntro();
      case 7: return _buildNearChart();
      case 8: return _buildNearResult();
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
    final isDistanceChart = _step == 3;
    final isNearChart = _step == 7;
    final isChecklist = _step == 1;

    // On checklist step: show only back button, no dark bar
    if (isChecklist) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                _restoreBrightness();
                Navigator.pop(context);
              },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDE4EC)),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: _ink, size: 18),
              ),
            ),
          ),
        ),
      );
    }

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
              const SizedBox(width: 12),
              if (isDistanceChart) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _teal3.withValues(alpha: 0.3)),
                  ),
                  child: Text(_eyeOrder[_currentEyeIndex],
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, fontWeight: FontWeight.w800, color: _teal3)),
                ),
                const SizedBox(width: 8),
                Text('LogMAR ${_rows[_currentRow]['logmar']}',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$_letterIndex/5',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8))),
                ),
                const SizedBox(width: 8),
                Icon(Icons.timer_rounded, size: 11, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 3),
                Text(_testDuration,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5))),
              ] else if (isNearChart) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _teal3.withValues(alpha: 0.3)),
                  ),
                  child: Text('OU — 40cm',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, fontWeight: FontWeight.w800, color: _teal3)),
                ),
                const SizedBox(width: 8),
                Text('LogMAR ${_rows[_nearRow]['logmar']}',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$_nearLetterIndex/5',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8))),
                ),
                const SizedBox(width: 8),
                Icon(Icons.timer_rounded, size: 11, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 3),
                Text(_testDuration,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5))),
              ] else ...[
                const Spacer(),
                if (_unsyncedCount > 0)
                  Container(
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
              ],
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

  // ── Location detection ────────────────────────────────────────────────────────────
  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _detectingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium));
      final placemarks = await placemarkFromCoordinates(
          pos.latitude, pos.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();
        _newVillageCtrl.text = parts.take(2).join(', ');
      }
    } catch (_) {}
    if (mounted) setState(() => _detectingLocation = false);
  }

  int _calcAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) age--;
    return age;
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

  Widget _newPatientForm() {
    const conditions = [
      {'label': 'Red Eyes',          'icon': Icons.remove_red_eye_rounded},
      {'label': 'Swollen Eyes',      'icon': Icons.visibility_off_rounded},
      {'label': 'Eye Discharge',     'icon': Icons.water_drop_rounded},
      {'label': 'Blurred Vision',    'icon': Icons.blur_on_rounded},
      {'label': 'Eye Pain',          'icon': Icons.warning_amber_rounded},
      {'label': 'Previous Surgery',  'icon': Icons.medical_services_rounded},
      {'label': 'Wears Glasses',     'icon': Icons.remove_red_eye_outlined},
      {'label': 'Diabetes',          'icon': Icons.monitor_heart_rounded},
      {'label': 'Hypertension',      'icon': Icons.favorite_rounded},
    ];

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
          // Photo capture
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: _newPhotoPath != null
                          ? Colors.transparent
                          : _teal.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _newPhotoPath != null
                            ? _teal : const Color(0xFFDDE4EC),
                        width: 2,
                      ),
                    ),
                    child: _newPhotoPath != null && File(_newPhotoPath!).existsSync()
                        ? ClipOval(
                            child: Image.file(
                              File(_newPhotoPath!),
                              fit: BoxFit.cover,
                              width: 90, height: 90,
                              errorBuilder: (_, __, ___) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_rounded,
                                      size: 24, color: _teal),
                                  const SizedBox(height: 4),
                                  Text('Photo',
                                      style: GoogleFonts.inter(
                                          fontSize: 10, fontWeight: FontWeight.w600,
                                          color: _teal)),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_rounded,
                                  size: 24, color: _teal),
                              const SizedBox(height: 4),
                              Text('Photo',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, fontWeight: FontWeight.w600,
                                      color: _teal)),
                            ],
                          ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: _teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Full name
          _newField(_newNameCtrl, 'Full Name', Icons.person_rounded),
          const SizedBox(height: 8),
          // DOB + Gender
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                          const Duration(days: 365 * 25)),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                      helpText: 'Select Date of Birth',
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _teal,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _newDob = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _newDob != null
                            ? _teal.withValues(alpha: 0.4)
                            : const Color(0xFFEEF2F6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake_rounded,
                            size: 16,
                            color: _newDob != null
                                ? _teal : const Color(0xFF8FA0B4)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _newDob == null
                              ? Text('Date of Birth',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF8FA0B4)))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_newDob!.day}/${_newDob!.month}/${_newDob!.year}',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF1A2A3D),
                                          fontWeight: FontWeight.w600)),
                                    Text(
                                      '${_calcAge(_newDob!)} years old',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: _teal)),
                                  ],
                                ),
                        ),
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: Color(0xFF8FA0B4)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFEEF2F6), width: 1.5),
                ),
                child: Row(
                  children: ['M', 'F'].map((g) {
                    final active = _newGender == g;
                    return GestureDetector(
                      onTap: () => setState(() => _newGender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? _teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(g,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF8FA0B4))),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Village / Area with auto-detect
          Row(
            children: [
              Expanded(
                child: _newField(
                    _newVillageCtrl, 'Village / Area',
                    Icons.location_on_rounded),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _detectingLocation ? null : _detectLocation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _detectingLocation
                        ? const Color(0xFFEEF2F6)
                        : _teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _detectingLocation
                          ? const Color(0xFFEEF2F6)
                          : _teal.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: _detectingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _teal))
                      : const Icon(Icons.my_location_rounded,
                          size: 20, color: _teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Current conditions
          Text('Current Eye Conditions',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 4),
          Text('Select all that apply',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF8FA0B4))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: conditions.map((c) {
              final label = c['label'] as String;
              final icon  = c['icon'] as IconData;
              final selected = _newConditions.contains(label);
              return GestureDetector(
                onTap: () => setState(() => selected
                    ? _newConditions.remove(label)
                    : _newConditions.add(label)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? _teal.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? _teal
                          : const Color(0xFFDDE4EC),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 13,
                          color: selected
                              ? _teal : const Color(0xFF8FA0B4)),
                      const SizedBox(width: 5),
                      Text(label,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? _teal
                                  : const Color(0xFF5E7291))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Register button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final name = _newNameCtrl.text.trim();
                final vil  = _newVillageCtrl.text.trim();
                if (name.isEmpty || _newDob == null || vil.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _newDob == null
                            ? 'Please select a date of birth'
                            : 'Please fill in all required fields',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white)),
                      backgroundColor: _red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                final age = _calcAge(_newDob!);
                final id  = 'PAT-NEW-${DateTime.now().millisecondsSinceEpoch % 100000}';
                setState(() {
                  _patientListRuntime.insert(0, {
                    'id': id,
                    'name': name,
                    'age': '$age',
                    'dob': '${_newDob!.day}/${_newDob!.month}/${_newDob!.year}',
                    'gender': _newGender,
                    'village': vil,
                    'conditions': _newConditions.join(', '),
                  });
                  _selectedPatientId = id;
                  _showNewPatientForm = false;
                  _newNameCtrl.clear();
                  _newVillageCtrl.clear();
                  _newDob = null;
                  _newConditions.clear();
                  _newPhotoPath = null;
                });
              },
              icon: const Icon(Icons.check_rounded,
                  size: 16, color: Colors.white),
              label: Text('Register & Select',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _teal.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: _teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mark the floor at exactly 2 metres from the screen before starting.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF5E7291))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 10),
          // ── Check 2: Screen brightness ──────────────────────────────────
          _checkTile(
            icon: Icons.brightness_high_rounded,
            title: 'Screen Brightness',
            subtitle: _brightnessSet
                ? 'Set to 100% automatically'
                : 'Setting screen brightness...',
            state: _brightnessSet ? _CheckState.pass : _CheckState.loading,
          ),
          const SizedBox(height: 10),
          // ── Check 3: Face detection ─────────────────────────────────────
          _checkTile(
            icon: Icons.face_rounded,
            title: 'Face Detection at 2 Metres',
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
    // Size based on fixed 2m testing distance
    final baseMm = row['mm'] as double;
    final size   = _mmToPx(baseMm, context);

    // ── Normal chart ─────────────────────────────────────────────────────
    return Column(
      children: [
        // Row progress
        LinearProgressIndicator(
          value: (_currentRow + 1) / _rows.length,
          backgroundColor: const Color(0xFFEEF2F6),
          color: _teal, minHeight: 3,
        ),
        // Single E display with bounding box + 5-dot progress
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // 5-dot progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    Color dotColor;
                    if (i < _letterIndex) {
                      dotColor = _green;
                    } else if (i == _letterIndex) {
                      dotColor = _teal;
                    } else {
                      dotColor = const Color(0xFFEEF2F6);
                    }
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _letterIndex ? 20 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // E with ETDRS bounding box (hidden when examiner masking on)
                LayoutBuilder(builder: (ctx, constraints) {
                  final maxH = constraints.maxHeight * 0.9;
                  final maxW = constraints.maxWidth  * 0.45;
                  final s = size.clamp(0.0, maxH < maxW ? maxH : maxW);
                  return CustomPaint(
                    painter: _BoundingBoxPainter(size: s),
                    child: Padding(
                      padding: EdgeInsets.all(s * 0.6),
                      child: RotatedBox(
                              quarterTurns: _currentRotation,
                              child: CustomPaint(
                                size: Size(s * 0.8, s),
                                painter: _ETumbleEPainter(color: _ink),
                              ),
                            ),
                    ),
                  );
                }),

                const Spacer(),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: const Color(0xFFF8FAFB),
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Which way is the E facing?',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF8FA0B4))),
                const SizedBox(height: 5),
                _dirBtn(Icons.arrow_upward_rounded, 3),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dirBtn(Icons.arrow_back_rounded, 2),
                    const SizedBox(width: 10),
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.remove_red_eye_rounded,
                          size: 20, color: Color(0xFF8FA0B4)),
                    ),
                    const SizedBox(width: 10),
                    _dirBtn(Icons.arrow_forward_rounded, 0),
                  ],
                ),
                const SizedBox(height: 5),
                _dirBtn(Icons.arrow_downward_rounded, 1),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _recordCantTell,
                    icon: const Icon(Icons.help_outline_rounded,
                        size: 16, color: Color(0xFF8FA0B4)),
                    label: Text("Can't Tell",
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: const Color(0xFF5E7291))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      side: const BorderSide(color: Color(0xFFDDE4EC), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dirBtn(IconData icon, int quarterTurns) {
    return GestureDetector(
      onTap: () => _recordResponse(quarterTurns == _currentRotation),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE4EC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: _ink),
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
              () => setState(() => _step = 2),
            )
          else
            _continueBtn('View Near Vision Test', _goToSummary),
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

  // ── Step 6: Near Vision Intro ─────────────────────────────────────────────────────
  Widget _buildNearVisionIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _stepBar(5),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withValues(alpha: 0.08),
                  border: Border.all(color: _teal.withValues(alpha: 0.25), width: 2),
                ),
                child: Icon(Icons.menu_book_rounded,
                    size: 64, color: _teal.withValues(alpha: 0.5)),
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
            child: Text('Near Vision — Both Eyes Open',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _teal)),
          ),
          const SizedBox(height: 16),
          Text('Near Vision Test',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2A3D))),
          const SizedBox(height: 10),
          Text(
            'Distance tests are complete. Now test near vision.\n'
            'Ask the patient to hold the device at 40 cm (arm\'s length) '
            'with BOTH eyes open.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF5E7291), height: 1.6)),
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
                  const Icon(Icons.tips_and_updates_rounded, size: 15, color: _amber),
                  const SizedBox(width: 8),
                  Text('Setup instructions',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3D))),
                ]),
                const SizedBox(height: 10),
                ...[
                  'Patient keeps BOTH eyes open — no covering needed',
                  'Hold device at exactly 40 cm from the eyes',
                  'Device should be at eye level',
                  'Patient wears reading glasses if they use them',
                  'Ensure screen brightness is at maximum',
                ].map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                            color: _amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF5E7291),
                              height: 1.5))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _continueBtn('Begin Near Vision Test', () {
            setState(() {
              _cameraReady = false;
              _nearFaceDetected = false;
              _nearFaceAtDistance = false;
              _step = 7;
            });
            _initNearCamera();
          }),
        ],
      ),
    );
  }

  // ── Step 7: Near Vision Chart ───────────────────────────────────────────────────
  Widget _buildNearChart() {
    // ── 40cm face detection gate ───────────────────────────────────────────────
    if (!_nearFaceAtDistance) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('Hold device at 40 cm',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _teal)),
            ),
            const SizedBox(height: 16),
            Text('Position for Near Vision',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2A3D))),
            const SizedBox(height: 8),
            Text(
              'Hold the device at arm\'s length (40 cm) with BOTH eyes open.\n'
              'Keep still until the distance is confirmed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF5E7291), height: 1.6)),
            const SizedBox(height: 20),
            if (_cameraReady && _cameraCtrl != null)
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
                          faceDetected: _nearFaceDetected,
                          correctDistance: _nearFaceAtDistance,
                        ),
                      ),
                      Positioned(
                        bottom: 10, left: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (_nearFaceDetected ? _amber : _ink)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _nearFaceDetected
                                    ? Icons.center_focus_strong_rounded
                                    : Icons.face_rounded,
                                color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _nearFaceDetected
                                    ? 'Face found — confirming 40 cm...'
                                    : 'Looking for face...',
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
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: _teal, strokeWidth: 2),
                ),
              ),
          ],
        ),
      );
    }

    // ── Near chart (40cm confirmed) ───────────────────────────────────────────────
    final row    = _rows[_nearRow];
    final logmar = row['logmar'] as String;
    // Near vision at 40cm = 0.4m (base measurements at 2m, scale by 0.4/2.0)
    final baseMm = row['mm'] as double;
    final scaledMm = baseMm * (400.0 / 2000.0);
    final size   = _mmToPx(scaledMm, context);

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_nearRow + 1) / _rows.length,
          backgroundColor: const Color(0xFFEEF2F6),
          color: _teal, minHeight: 3,
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    Color dotColor;
                    if (i < _nearLetterIndex) dotColor = _green;
                    else if (i == _nearLetterIndex) dotColor = _teal;
                    else dotColor = const Color(0xFFEEF2F6);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _nearLetterIndex ? 20 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                CustomPaint(
                  painter: _BoundingBoxPainter(size: size),
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.6),
                    child: RotatedBox(
                      quarterTurns: _nearRotation,
                      child: CustomPaint(
                        size: Size(size * 0.8, size),
                        painter: _ETumbleEPainter(color: _ink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: const Color(0xFFF8FAFB),
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Which way is the E facing?',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF8FA0B4))),
                const SizedBox(height: 5),
                _nearDirBtn(Icons.arrow_upward_rounded, 3),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _nearDirBtn(Icons.arrow_back_rounded, 2),
                    const SizedBox(width: 10),
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.remove_red_eye_rounded,
                          size: 20, color: Color(0xFF8FA0B4)),
                    ),
                    const SizedBox(width: 10),
                    _nearDirBtn(Icons.arrow_forward_rounded, 0),
                  ],
                ),
                const SizedBox(height: 5),
                _nearDirBtn(Icons.arrow_downward_rounded, 1),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _recordNearCantTell,
                    icon: const Icon(Icons.help_outline_rounded,
                        size: 16, color: Color(0xFF8FA0B4)),
                    label: Text("Can't Tell",
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: const Color(0xFF5E7291))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      side: const BorderSide(color: Color(0xFFDDE4EC), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _nearDirBtn(IconData icon, int quarterTurns) =>
    GestureDetector(
      onTap: () => _recordNearResponse(quarterTurns == _nearRotation),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE4EC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: _ink),
      ),
    );

  // ── Step 8: Near Vision Result ──────────────────────────────────────────────────
  Widget _buildNearResult() {
    if (_nearResult == null) return const SizedBox();
    final logmar = _nearResult!['logmar'] as String;
    final dur    = _nearResult!['duration'] as String;
    final ct     = _nearResult!['cantTell'] as int;
    final cls    = _vaClass(logmar);
    final col    = _vaColor(logmar);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBar(6),
          const SizedBox(height: 24),
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
                  child: const Center(
                    child: Text('OU',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Near Vision — Both Eyes',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF8FA0B4))),
                const SizedBox(height: 6),
                Text(double.tryParse(logmar) != null
                    ? _toSnellen(logmar) : logmar,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 48, fontWeight: FontWeight.w900, color: col)),
                if (double.tryParse(logmar) != null)
                  Text('LogMAR $logmar',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: col.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(cls,
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: col)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip(Icons.timer_rounded, dur, 'Duration'),
                    const SizedBox(width: 12),
                    _statChip(Icons.help_outline_rounded,
                        '$ct', "Can't Tell"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _blurPreview(logmar),
          const SizedBox(height: 28),
          _continueBtn('View Full Summary', _goToFinalSummary),
        ],
      ),
    );
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
          const SizedBox(height: 6),
          Text('Distance Vision (Monocular)',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF8FA0B4))),
          const SizedBox(height: 12),
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
          // Near vision result card
          if (_nearResult != null) ...[
            const SizedBox(height: 16),
            Text('Near Vision (Binocular — 40cm)',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: const Color(0xFF8FA0B4))),
            const SizedBox(height: 10),
            Builder(builder: (_) {
              final logmar = _nearResult!['logmar'] as String;
              final dur    = _nearResult!['duration'] as String;
              final ct     = _nearResult!['cantTell'] as int;
              final cls    = _vaClass(logmar);
              final col    = _vaColor(logmar);
              return Container(
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
                        child: Text('OU',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, fontWeight: FontWeight.w800,
                                color: col)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Both Eyes — Near',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: const Color(0xFF8FA0B4))),
                          const SizedBox(height: 2),
                          Text(cls,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A2A3D))),
                          if (ct > 0)
                            Text("$ct can't tell",
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
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: col)),
                        if (double.tryParse(logmar) != null)
                          Text('LogMAR $logmar',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: col.withValues(alpha: 0.7))),
                        Text(dur,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF8FA0B4))),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
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
                          nearResult: _nearResult,
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

// ETDRS bounding box — stroke = 1/5 of E size, gap = 1/2 of E size
class _BoundingBoxPainter extends CustomPainter {
  final double size;
  const _BoundingBoxPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final strokeW = size / 5;          // arm thickness = 1 unit
    final gap     = size / 2;          // gap between E and box
    final cx = canvasSize.width  / 2;
    final cy = canvasSize.height / 2;
    final half = size / 2 + gap + strokeW / 2;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: half * 2, height: half * 2);
    final paint = Paint()
      ..color = const Color(0xFF04091A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_BoundingBoxPainter old) => old.size != size;
}

// ETDRS Tumbling E — drawn on a 5×5 grid
// Unit (u) = size/5
// Letter: width=4u, height=5u
// 3 arms: top, middle, bottom — each 1u thick
// 2 gaps between arms: each 1u
// Spine on left: 1u wide, full 5u height
class _ETumbleEPainter extends CustomPainter {
  final Color color;
  const _ETumbleEPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.height / 5;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Spine
    canvas.drawRect(Rect.fromLTWH(0, 0, u, size.height), paint);
    // Top arm
    canvas.drawRect(Rect.fromLTWH(0, 0, u * 4, u), paint);
    // Middle arm — 4u wide per ETDRS 5×5 rule (same as top/bottom)
    canvas.drawRect(Rect.fromLTWH(0, u * 2, u * 4, u), paint);
    // Bottom arm
    canvas.drawRect(Rect.fromLTWH(0, u * 4, u * 4, u), paint);
  }

  @override
  bool shouldRepaint(_ETumbleEPainter old) => old.color != color;
}
