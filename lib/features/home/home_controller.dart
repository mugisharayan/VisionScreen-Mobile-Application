import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/screening_repository.dart';
import '../../services/chw_profile_preferences.dart';
import '../../services/permission_coordinator.dart';
import '../../services/sync/sync_service.dart';
import '../../utils/app_constants.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required int tipCount,
    ScreeningRepository? screeningRepository,
    SyncService? syncService,
  }) : _tipCount = tipCount,
       _screeningRepository =
           screeningRepository ?? ScreeningRepository.instance,
       _syncService = syncService ?? SyncService.instance;

  final int _tipCount;
  final ScreeningRepository _screeningRepository;
  final SyncService _syncService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _clockTimer;
  Timer? _tipTimer;
  bool _initialized = false;

  String _chwName = '';
  String _chwPhoto = '';
  int _totalScreened = 0;
  int _totalReferred = 0;
  int _unsyncedCount = 0;
  int _notificationCount = 0;
  bool _isSyncing = false;
  bool _syncConfigured = false;
  String _lastSyncError = '';
  List<Map<String, dynamic>> _recentScreenings = [];
  List<Map<String, dynamic>> _referredPatients = [];
  bool _isOffline = false;
  String _locationLabel = 'Tap to check location';
  DateTime _now = DateTime.now();
  int _tipIndex = 0;

  String get chwName => _chwName;
  String get chwPhoto => _chwPhoto;
  int get totalScreened => _totalScreened;
  int get totalReferred => _totalReferred;
  int get unsyncedCount => _unsyncedCount;
  int get notificationCount => _notificationCount;
  bool get isSyncing => _isSyncing;
  bool get syncConfigured => _syncConfigured;
  String get lastSyncError => _lastSyncError;
  List<Map<String, dynamic>> get recentScreenings => _recentScreenings;
  List<Map<String, dynamic>> get referredPatients => _referredPatients;
  bool get isOffline => _isOffline;
  String get locationLabel => _locationLabel;
  DateTime get now => _now;
  int get tipIndex => _tipIndex;

  String get greeting {
    final hour = _now.hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  String get firstName =>
      _chwName.trim().isEmpty ? 'CHW' : _chwName.trim().split(' ').first;

  String get initials => _chwName.trim().isEmpty
      ? 'VS'
      : _chwName
            .trim()
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0])
            .take(2)
            .join()
            .toUpperCase();

  String formatTime(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  String formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dateTime.weekday - 1]}, ${dateTime.day} ${months[dateTime.month - 1]}';
  }

  String timeAgo(String iso) {
    try {
      final difference = DateTime.now().difference(DateTime.parse(iso));
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      }
      if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      }
      return '${difference.inDays}d ago';
    } catch (_) {
      return 'Today';
    }
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _startClock();
    _startTips();
    await _bindConnectivity();
    await loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([_loadChwProfile(), _loadDbStats()]);
  }

  Future<void> refresh() => loadAll();

  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      return const SyncResult(
        success: false,
        appliedChanges: 0,
        errorMessage: 'Sync already in progress.',
      );
    }
    _isSyncing = true;
    notifyListeners();
    try {
      final result = await _syncService.syncNow();
      await _loadDbStats();
      _syncConfigured = _syncService.isConfigured;
      final prefs = await SharedPreferences.getInstance();
      _lastSyncError = prefs.getString(AppStrings.prefLastSyncError) ?? '';
      return result;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<AppPermissionResult> refreshLocation(BuildContext context) async {
    final permission = await PermissionCoordinator.instance.requestHomeLocation(
      context,
    );
    if (!permission.isGranted) {
      _locationLabel = permission.status == AppPermissionStatus.serviceDisabled
          ? 'Enable location services'
          : 'Location permission not granted';
      notifyListeners();
      return permission;
    }

    _locationLabel = 'Checking location...';
    notifyListeners();
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        _locationLabel = 'Location unavailable';
        notifyListeners();
        return permission;
      }

      _locationLabel =
          '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
      notifyListeners();

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 6));
        if (placemarks.isNotEmpty) {
          final parts = [
            placemarks.first.subLocality,
            placemarks.first.locality,
            placemarks.first.administrativeArea,
          ].whereType<String>().where((value) => value.isNotEmpty).toList();
          if (parts.isNotEmpty) {
            _locationLabel = parts.join(', ');
            notifyListeners();
          }
        }
      } catch (_) {}
    } catch (_) {
      _locationLabel = 'Location unavailable';
      notifyListeners();
    }
    return permission;
  }

  void clearNotifications() {
    if (_notificationCount == 0) {
      return;
    }
    _notificationCount = 0;
    notifyListeners();
  }

  Future<void> _bindConnectivity() async {
    final initial = await Connectivity().checkConnectivity();
    _isOffline = initial.every((result) => result == ConnectivityResult.none);
    notifyListeners();

    await _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _isOffline = results.every((result) => result == ConnectivityResult.none);
      notifyListeners();
    });
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  void _startTips() {
    if (_tipCount <= 0) {
      return;
    }
    _tipTimer?.cancel();
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _tipIndex = (_tipIndex + 1) % _tipCount;
      notifyListeners();
    });
  }

  Future<void> _loadChwProfile() async {
    final profile = await ChwProfilePreferences.load();
    final prefs = await SharedPreferences.getInstance();
    _chwName = profile.name;
    _chwPhoto = profile.photoPath;
    _syncConfigured = _syncService.isConfigured;
    _lastSyncError = prefs.getString(AppStrings.prefLastSyncError) ?? '';
    notifyListeners();
  }

  Future<void> _loadDbStats() async {
    final outcomes = await _screeningRepository.getOutcomeCounts();
    final unsynced = await _screeningRepository.getUnsyncedCount();
    final recent = await _screeningRepository.getRecentScreeningsWithPatient(
      limit: 4,
    );
    final referred = await _screeningRepository.getReferredPatients();
    final notifications = await _screeningRepository.getNotifications();

    _totalScreened = (outcomes['pass'] ?? 0) + (outcomes['refer'] ?? 0);
    _totalReferred = outcomes['refer'] ?? 0;
    _unsyncedCount = unsynced;
    _recentScreenings = recent;
    _referredPatients = referred;
    _notificationCount = notifications
        .where((notification) => notification['read'] == false)
        .length;
    notifyListeners();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tipTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
