import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../repositories/patient_repository.dart';
import '../../repositories/screening_repository.dart';
import '../../services/chw_profile_preferences.dart';
import '../../utils/visual_acuity.dart';
import 'screening_constants.dart';

class ScreeningFlowController extends ChangeNotifier {
  ScreeningFlowController({
    PatientRepository? patientRepository,
    ScreeningRepository? screeningRepository,
  }) : _patientRepository = patientRepository ?? PatientRepository.instance,
       _screeningRepository =
           screeningRepository ?? ScreeningRepository.instance;

  final PatientRepository _patientRepository;
  final ScreeningRepository _screeningRepository;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _countdownTimer;
  Timer? _nearCountdownTimer;
  Timer? _testTimer;

  int _step = 0;
  String? _selectedPatientId;
  String _patientQuery = '';
  bool _showNewPatientForm = false;
  String _newGender = 'M';
  DateTime? _newDob;
  bool _detectingLocation = false;
  final List<String> _newConditions = [];
  String? _newPhotoPath;
  List<Map<String, String>> _patientListRuntime = [];
  int? _savedScreeningId;
  double _currentLux = 0.0;
  bool _luxChecked = false;
  bool _luxOk = false;
  bool _brightnessSet = false;
  double? _originalBrightness;
  int _currentEyeIndex = 0;
  int _currentRow = 0;
  int _currentRotation = 0;
  int _lastPassedRow = 0;
  int _letterIndex = 0;
  int _correctCount = 0;
  int _staircaseJumpIndex = 0;
  bool _staircasePhase = true;
  final List<Map<String, dynamic>> _eyeResults = [];
  int _cantTellCount = 0;
  int _nearRow = 0;
  int _nearLetterIndex = 0;
  int _nearCorrectCount = 0;
  int _nearLastPassedRow = 0;
  int _nearRotation = 0;
  bool _nearStaircasePhase = true;
  int _nearStaircaseJumpIndex = 0;
  int _nearCantTellCount = 0;
  Map<String, dynamic>? _nearResult;
  int _testSeconds = 0;
  bool _isOffline = false;
  int _unsyncedCount = 0;
  int _countdown = 0;
  int _nearCountdown = 0;

  int get step => _step;
  void setStep(int value) {
    if (_step == value) {
      return;
    }
    _step = value;
    notifyListeners();
  }

  String? get selectedPatientId => _selectedPatientId;
  void selectPatient(String? value) {
    if (_selectedPatientId == value) {
      return;
    }
    _selectedPatientId = value;
    notifyListeners();
  }

  String get patientQuery => _patientQuery;
  void setPatientQuery(String value) {
    if (_patientQuery == value) {
      return;
    }
    _patientQuery = value;
    notifyListeners();
  }

  bool get showNewPatientForm => _showNewPatientForm;
  void setShowNewPatientForm(bool value) {
    if (_showNewPatientForm == value) {
      return;
    }
    _showNewPatientForm = value;
    notifyListeners();
  }

  void toggleNewPatientForm() {
    _showNewPatientForm = !_showNewPatientForm;
    notifyListeners();
  }

  String get newGender => _newGender;
  void setNewGender(String value) {
    if (_newGender == value) {
      return;
    }
    _newGender = value;
    notifyListeners();
  }

  DateTime? get newDob => _newDob;
  void setNewDob(DateTime? value) {
    if (_newDob == value) {
      return;
    }
    _newDob = value;
    notifyListeners();
  }

  bool get detectingLocation => _detectingLocation;
  void setDetectingLocation(bool value) {
    if (_detectingLocation == value) {
      return;
    }
    _detectingLocation = value;
    notifyListeners();
  }

  List<String> get newConditions => List.unmodifiable(_newConditions);

  void toggleNewCondition(String value) {
    if (_newConditions.contains(value)) {
      _newConditions.remove(value);
    } else {
      _newConditions.add(value);
    }
    notifyListeners();
  }

  String? get newPhotoPath => _newPhotoPath;
  void setNewPhotoPath(String? value) {
    if (_newPhotoPath == value) {
      return;
    }
    _newPhotoPath = value;
    notifyListeners();
  }

  List<Map<String, String>> get patientListRuntime =>
      List.unmodifiable(_patientListRuntime);

  int? get savedScreeningId => _savedScreeningId;
  double get currentLux => _currentLux;
  bool get luxChecked => _luxChecked;
  bool get luxOk => _luxOk;
  bool get brightnessSet => _brightnessSet;
  double? get originalBrightness => _originalBrightness;
  void setOriginalBrightness(double? value) {
    if (_originalBrightness == value) {
      return;
    }
    _originalBrightness = value;
    notifyListeners();
  }
  bool get checklistDone => _luxOk && _brightnessSet;
  int get currentEyeIndex => _currentEyeIndex;
  int get currentRow => _currentRow;
  int get currentRotation => _currentRotation;
  int get lastPassedRow => _lastPassedRow;
  int get letterIndex => _letterIndex;
  int get correctCount => _correctCount;
  int get staircaseJumpIndex => _staircaseJumpIndex;
  bool get staircasePhase => _staircasePhase;
  List<Map<String, dynamic>> get eyeResults => List.unmodifiable(_eyeResults);
  int get cantTellCount => _cantTellCount;
  int get nearRow => _nearRow;
  int get nearLetterIndex => _nearLetterIndex;
  int get nearCorrectCount => _nearCorrectCount;
  int get nearLastPassedRow => _nearLastPassedRow;
  int get nearRotation => _nearRotation;
  bool get nearStaircasePhase => _nearStaircasePhase;
  int get nearStaircaseJumpIndex => _nearStaircaseJumpIndex;
  int get nearCantTellCount => _nearCantTellCount;
  Map<String, dynamic>? get nearResult => _nearResult;
  int get testSeconds => _testSeconds;
  bool get isOffline => _isOffline;
  int get unsyncedCount => _unsyncedCount;
  int get countdown => _countdown;
  int get nearCountdown => _nearCountdown;

  String get testDuration {
    final minutes = _testSeconds ~/ 60;
    final seconds = _testSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get needsReferral {
    final distancePoor = _eyeResults.any((result) {
      final value = double.tryParse(result['logmar'] as String);
      return value == null || value > 0.3;
    });
    final nearPoor =
        _nearResult != null &&
        (double.tryParse(_nearResult!['logmar'] as String) ?? 1.0) > 0.3;
    return distancePoor || nearPoor;
  }

  Future<void> initialize({
    required bool startWithNewPatient,
    String? existingPatientId,
  }) async {
    _showNewPatientForm = startWithNewPatient;
    if (existingPatientId != null) {
      _selectedPatientId = existingPatientId;
      _step = 1;
    }

    await loadUnsyncedCount();
    await loadPatients();
    if (existingPatientId != null) {
      runChecklist();
    }

    await _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _isOffline = results.every((result) => result == ConnectivityResult.none);
      notifyListeners();
    });
  }

  Future<void> loadPatients() async {
    final rows = await _patientRepository.getPatients(pageSize: 500);
    _patientListRuntime = rows
        .map(
          (row) => {
            'id': row['id'] as String,
            'name': row['name'] as String,
            'age': row['age'].toString(),
            'gender': row['gender'] as String,
            'village': row['village'] as String,
            'dob': (row['dob'] as String?) ?? '',
            'conditions': (row['conditions'] as String?) ?? '',
          },
        )
        .toList();
    notifyListeners();
  }

  void setLuxResult(double lux) {
    _currentLux = lux;
    _luxChecked = true;
    _luxOk = _currentLux >= screeningMinLux;
    notifyListeners();
  }

  void resetLightCheck() {
    _luxChecked = false;
    _luxOk = false;
    notifyListeners();
  }

  void setBrightnessReady(bool value) {
    _brightnessSet = value;
    notifyListeners();
  }

  void continueToChecklist() {
    _step = 1;
    notifyListeners();
  }

  void startDistanceChart() {
    _countdown = 3;
    notifyListeners();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      if (_countdown <= 0) {
        timer.cancel();
        _generateRotation();
        _startTestTimer();
        _step = 3;
      }
      notifyListeners();
    });
  }

  void startNearChart() {
    _nearCountdown = 3;
    notifyListeners();
    _nearCountdownTimer?.cancel();
    _nearCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _nearCountdown--;
      if (_nearCountdown <= 0) {
        timer.cancel();
        _step = 7;
        _generateNearRotation();
        _startTestTimer();
      }
      notifyListeners();
    });
  }

  void recordResponse(bool correct) {
    if (correct) {
      _correctCount++;
    }
    _letterIndex++;

    if (_letterIndex < 5) {
      _generateRotation();
      notifyListeners();
      return;
    }

    final passed = _correctCount >= 4;
    _letterIndex = 0;
    _correctCount = 0;

    if (passed) {
      _lastPassedRow = _currentRow;
      _advanceStaircase(passed: true);
    } else {
      _advanceStaircase(passed: false);
    }
    notifyListeners();
  }

  void recordCantTell() {
    _cantTellCount++;
    _letterIndex++;
    if (_letterIndex < 5) {
      _generateRotation();
      notifyListeners();
      return;
    }

    final passed = _correctCount >= 4;
    _letterIndex = 0;
    _correctCount = 0;
    if (passed) {
      _lastPassedRow = _currentRow;
      _advanceStaircase(passed: true);
    } else {
      _advanceStaircase(passed: false);
    }
    notifyListeners();
  }

  void goToFinalSummary() {
    _step = 5;
    notifyListeners();
  }

  void recordNearResponse(bool correct) {
    if (correct) {
      _nearCorrectCount++;
    }
    _nearLetterIndex++;
    if (_nearLetterIndex < 5) {
      _generateNearRotation();
      notifyListeners();
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
    notifyListeners();
  }

  void recordNearCantTell() {
    _nearCantTellCount++;
    _nearLetterIndex++;
    if (_nearLetterIndex < 5) {
      _generateNearRotation();
      notifyListeners();
      return;
    }
    final passed = _nearCorrectCount >= 4;
    _nearLetterIndex = 0;
    _nearCorrectCount = 0;
    _advanceNearStaircase(passed: passed);
    notifyListeners();
  }

  Future<void> saveScreening() async {
    if (_selectedPatientId == null) {
      return;
    }
    final profile = await ChwProfilePreferences.load();

    var odLogmar = '';
    var osLogmar = '';
    var odCantTell = 0;
    var osCantTell = 0;
    var odDuration = '';
    var osDuration = '';

    for (final result in _eyeResults) {
      if (result['eye'] == 'OD') {
        odLogmar = result['logmar'] as String;
        odCantTell = result['cantTell'] as int;
        odDuration = result['duration'] as String;
      } else if (result['eye'] == 'OS') {
        osLogmar = result['logmar'] as String;
        osCantTell = result['cantTell'] as int;
        osDuration = result['duration'] as String;
      }
    }

    final nearLogmar = _nearResult?['logmar'] as String? ?? '';
    final nearCantTell = _nearResult?['cantTell'] as int? ?? 0;
    final nearDuration = _nearResult?['duration'] as String? ?? '';
    final outcome = needsReferral ? 'refer' : 'pass';

    _savedScreeningId = await _screeningRepository.insertScreening({
      'patient_id': _selectedPatientId,
      'screening_date': DateTime.now().toIso8601String(),
      'od_logmar': odLogmar,
      'os_logmar': osLogmar,
      'ou_near_logmar': nearLogmar,
      'od_snellen': odLogmar.isNotEmpty ? VisualAcuity.toSnellen(odLogmar) : '',
      'os_snellen': osLogmar.isNotEmpty ? VisualAcuity.toSnellen(osLogmar) : '',
      'ou_near_snellen': nearLogmar.isNotEmpty
          ? VisualAcuity.toSnellen(nearLogmar)
          : '',
      'od_cant_tell': odCantTell,
      'os_cant_tell': osCantTell,
      'near_cant_tell': nearCantTell,
      'od_duration': odDuration,
      'os_duration': osDuration,
      'near_duration': nearDuration,
      'outcome': outcome,
      'referral_facility': '',
      'referral_status': outcome == 'refer' ? 'pending' : '',
      'chw_name': profile.name,
      'synced': 0,
    });

    await loadUnsyncedCount();
    notifyListeners();
  }

  Future<void> loadUnsyncedCount() async {
    _unsyncedCount = await _screeningRepository.getUnsyncedCount();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> findPotentialDuplicates({
    required String name,
    required int age,
    required String village,
  }) {
    return _patientRepository.findPotentialDuplicates(
      name: name,
      age: age,
      village: village,
    );
  }

  Future<String> registerNewPatient({
    required String name,
    required int age,
    required DateTime dob,
    required String village,
    required String phone,
  }) async {
    final id = 'PAT-${DateTime.now().millisecondsSinceEpoch}';
    final newPatient = {
      'id': id,
      'name': name,
      'age': age,
      'dob': '${dob.day}/${dob.month}/${dob.year}',
      'gender': _newGender,
      'village': village,
      'phone': phone,
      'conditions': _newConditions.join(', '),
      'photo_path': _newPhotoPath ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };
    await _patientRepository.insertPatient(newPatient);
    await loadPatients();
    _selectedPatientId = id;
    _showNewPatientForm = false;
    _newDob = null;
    _newConditions.clear();
    _newPhotoPath = null;
    notifyListeners();
    return id;
  }

  void runChecklist() {
    _step = 1;
    notifyListeners();
  }

  void prepareNextEye() {
    _step = 2;
    notifyListeners();
  }

  void jumpToNearIntro() {
    _step = 6;
    notifyListeners();
  }

  void disposeResources() {
    _countdownTimer?.cancel();
    _nearCountdownTimer?.cancel();
    _testTimer?.cancel();
    _connectivitySub?.cancel();
  }

  void _generateRotation() {
    _currentRotation = Random().nextInt(4);
  }

  void _startTestTimer() {
    _testSeconds = 0;
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _testSeconds++;
      notifyListeners();
    });
  }

  void _stopTestTimer() {
    _testTimer?.cancel();
  }

  void _advanceStaircase({required bool passed}) {
    if (_staircasePhase) {
      if (passed) {
        _staircaseJumpIndex++;
        if (_staircaseJumpIndex >= screeningStaircaseJumps.length) {
          _finishEye(screeningRows[_lastPassedRow]['logmar'] as String);
          return;
        }
        _currentRow = screeningStaircaseJumps[_staircaseJumpIndex];
      } else {
        _staircasePhase = false;
        _currentRow = (_currentRow + 1).clamp(0, screeningRows.length - 1);
        if (_currentRow >= screeningRows.length - 1) {
          _finishEye(screeningRows[_lastPassedRow]['logmar'] as String);
          return;
        }
      }
    } else {
      if (passed) {
        _lastPassedRow = _currentRow;
        final next = _currentRow - 1;
        if (next < 0) {
          _finishEye(screeningRows[_lastPassedRow]['logmar'] as String);
          return;
        }
        _currentRow = next;
      } else {
        _finishEye(screeningRows[_lastPassedRow]['logmar'] as String);
        return;
      }
    }
    _generateRotation();
  }

  void _finishEye(String result) {
    _stopTestTimer();
    final isLastEye = _currentEyeIndex >= screeningEyeOrder.length - 1;
    _eyeResults.add({
      'eye': screeningEyeOrder[_currentEyeIndex],
      'logmar': result,
      'duration': testDuration,
      'cantTell': _cantTellCount,
    });

    if (isLastEye) {
      _nearRow = 0;
      _nearLetterIndex = 0;
      _nearCorrectCount = 0;
      _nearLastPassedRow = 0;
      _nearStaircasePhase = true;
      _nearStaircaseJumpIndex = 0;
      _nearCantTellCount = 0;
      _nearResult = null;
      _step = 6;
      return;
    }

    _currentEyeIndex++;
    _currentRow = 0;
    _lastPassedRow = 0;
    _letterIndex = 0;
    _correctCount = 0;
    _staircaseJumpIndex = 0;
    _staircasePhase = true;
    _cantTellCount = 0;
    _generateRotation();
    _step = 2;
  }

  void _generateNearRotation() {
    _nearRotation = Random().nextInt(4);
  }

  void _advanceNearStaircase({required bool passed}) {
    if (_nearStaircasePhase) {
      if (passed) {
        _nearStaircaseJumpIndex++;
        if (_nearStaircaseJumpIndex >= screeningStaircaseJumps.length) {
          _finishNear(screeningRows[_nearLastPassedRow]['logmar'] as String);
          return;
        }
        _nearRow = screeningStaircaseJumps[_nearStaircaseJumpIndex];
      } else {
        _nearStaircasePhase = false;
        _nearRow = (_nearRow + 1).clamp(0, screeningRows.length - 1);
        if (_nearRow >= screeningRows.length - 1) {
          _finishNear(screeningRows[_nearLastPassedRow]['logmar'] as String);
          return;
        }
      }
    } else {
      if (passed) {
        _nearLastPassedRow = _nearRow;
        final next = _nearRow - 1;
        if (next < 0) {
          _finishNear(screeningRows[_nearLastPassedRow]['logmar'] as String);
          return;
        }
        _nearRow = next;
      } else {
        _finishNear(screeningRows[_nearLastPassedRow]['logmar'] as String);
        return;
      }
    }
    _generateNearRotation();
  }

  void _finishNear(String logmar) {
    _stopTestTimer();
    _nearResult = {
      'logmar': logmar,
      'duration': testDuration,
      'cantTell': _nearCantTellCount,
    };
    _step = 5;
    unawaited(saveScreening());
  }
}
