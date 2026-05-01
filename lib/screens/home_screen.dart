import 'dart:async';
import 'dart:async' show TimeoutException;
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart' show AppColors;
import 'training_screen.dart';
import 'auth_widgets.dart' show AuthEyePainter;
import 'notifications_screen.dart';
import 'patients_screen.dart';
import 'new_screening_screen.dart';
import 'bulk_mode_screen.dart';

import 'analytics_screen.dart';
import 'settings_screen.dart';
import '../db/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _notificationCount = 0;
  bool _isSyncing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  String _locationLabel = 'Detecting location...';
  bool _showClinicalTipDialog = false;

  String _chwName = '';
  String _chwCenter = '';
  String _chwDistrict = '';
  String _chwPhoto = '';

  int _totalScreened = 0;
  int _totalReferred = 0;
  int _unsyncedCount = 0;
  List<Map<String, dynamic>> _recentScreenings = [];
  List<Map<String, dynamic>> _referredPatients = [];

  final List<Map<String, dynamic>> _tips = [
    {'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFF59E0B), 'text': 'Ensure adequate room lighting before starting a vision test.', 'image': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400&q=80'},
    {'icon': Icons.straighten_rounded, 'color': AppColors.green, 'text': 'Always confirm the patient is exactly 3 metres from the screen.', 'image': 'https://images.unsplash.com/photo-1581595220892-b0739db3ba8c?w=400&q=80'},
    {'icon': Icons.remove_red_eye_rounded, 'color': Color(0xFF3B82F6), 'text': 'Test each eye separately â€” cover one eye completely before testing the other.', 'image': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=400&q=80'},
    {'icon': Icons.elderly_rounded, 'color': Color(0xFF10B981), 'text': 'For elderly patients, apply the 6/18 threshold â€” not the adult 6/12 standard.', 'image': 'https://images.unsplash.com/photo-1516307365426-bea591f05011?w=400&q=80'},
    {'icon': Icons.child_care_rounded, 'color': Color(0xFF8B5CF6), 'text': 'Children may need encouragement â€” demonstrate the E direction yourself first.', 'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80'},
    {'icon': Icons.visibility_off_rounded, 'color': Color(0xFFEF4444), 'text': 'Ask patients to remove glasses before the unaided vision test begins.', 'image': 'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=400&q=80'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _now = DateTime.now());
      },
    );
    _loadChwProfile();
    _loadDbStats();
    
    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        setState(() => _isOffline = results.every(
            (r) => r == ConnectivityResult.none));
      }
    });
    // Listen for connectivity changes
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() => _isOffline = results.every(
            (r) => r == ConnectivityResult.none));
      }
    });
    
    // Check if first time user and show clinical tip dialog
    _checkFirstTimeUser();
    
    // Fetch real location
    _fetchLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clockTimer.cancel();
    _connectivitySub.cancel();
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time_home') ?? true;
    
    if (isFirstTime) {
      // Mark as not first time
      await prefs.setBool('is_first_time_home', false);
      
      // Show clinical tip dialog after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showTipDialog();
        }
      });
    }
  }

  Future<void> _loadChwProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _chwName     = prefs.getString('chw_name')    ?? '';
      _chwCenter   = prefs.getString('chw_center')  ?? '';
      _chwDistrict = prefs.getString('chw_district') ?? '';
      _chwPhoto    = prefs.getString('chw_photo')    ?? '';
    });
  }

  Future<void> _loadDbStats() async {
    final outcomes = await DatabaseHelper.instance.getOutcomeCounts();
    final unsynced = await DatabaseHelper.instance.getUnsyncedCount();
    final recent = await DatabaseHelper.instance.getRecentScreeningsWithPatient(limit: 4);
    final referred = await DatabaseHelper.instance.getReferredPatients();
    if (!mounted) return;
    setState(() {
      _totalScreened = (outcomes['pass'] ?? 0) + (outcomes['refer'] ?? 0);
      _totalReferred = outcomes['refer'] ?? 0;
      _unsyncedCount = unsynced;
      _recentScreenings = recent;
      _referredPatients = referred;
    });
    final notifications = await DatabaseHelper.instance.getNotifications();
    if (!mounted) return;
    setState(() => _notificationCount = notifications.where((n) => n['read'] == false).length);
  }

  Future<void> _onRefresh() async {
    await _loadChwProfile();
    await _loadDbStats();
  }

  void _doSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync complete! $_unsyncedCount records uploaded.',
              style: GoogleFonts.poppins(fontSize: 12)),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
             child: RefreshIndicator(
               onRefresh: _onRefresh,
               color: AppColors.green,
               child: SingleChildScrollView(
                 physics: const AlwaysScrollableScrollPhysics(),
                 padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                child: Column(
            mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isOffline) _buildOfflineBanner(),
                    _buildSectionLabel('Quick Actions'),
                    _buildActionGrid(),
                    const SizedBox(height: 8),
                    _buildPassRateStrip(),
                    const SizedBox(height: 10),
                    _buildSectionLabel('Recent Patients'),
                    _buildRecentPatients(),
                    const SizedBox(height: 10),
                    _buildReferralFollowUps(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => const _NotificationsSheet(),
    );
  }

  Future<void> _fetchLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationLabel = 'Enable GPS in settings');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationLabel = 'Location permission denied');
          _showLocationPermissionDialog(openSettings: true);
        }
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationLabel = 'Location permission denied');
          _showLocationPermissionDialog(openSettings: false);
        }
        return;
      }

      if (mounted) setState(() => _locationLabel = 'Detecting location...');

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Show coordinates immediately while geocoding
      final coordLabel =
          '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      if (mounted) setState(() => _locationLabel = coordLabel);

      // Try reverse geocoding â€” may fail if offline
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude)
                .timeout(const Duration(seconds: 6));
        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;
          final parts = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).toList();
          if (parts.isNotEmpty) {
            setState(() => _locationLabel = parts.join(', '));
          }
        }
      } catch (_) {
        // Geocoding failed (offline) â€” keep showing coordinates
      }
    } on TimeoutException {
      if (mounted) setState(() => _locationLabel = 'GPS timeout â€” tap to retry');
    } catch (e) {
      if (mounted) setState(() => _locationLabel = 'Tap to retry location');
    }
  }

  void _showLocationPermissionDialog({required bool openSettings}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.3),
                            width: 2),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.green, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text('Location Permission Required',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark)),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      openSettings
                          ? 'Location permission has been permanently denied. Please enable it in your device settings to show your current location.'
                          : 'VisionScreen needs your location to display where screenings are being conducted. Please allow location access.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    // Primary button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (openSettings) {
                            await Geolocator.openAppSettings();
                          } else {
                            await _fetchLocation();
                          }
                        },
                        icon: Icon(
                          openSettings
                              ? Icons.settings_rounded
                              : Icons.location_on_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          openSettings ? 'Open Settings' : 'Allow Location',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Skip button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Skip for now',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _TipDialogContent(tips: _tips),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: _HomeWaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.greenDark, AppColors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _HomeDotPainter())),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                    // â”€â”€ Brand row â”€â”€
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo left
                        Row(children: [
                          Container(
                             width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                               borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Center(
                              child: CustomPaint(
                                 size: const Size(24, 24),
                                painter: AuthEyePainter(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                               style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w900),
                              children: const [
                                TextSpan(text: 'Vision', style: TextStyle(color: Colors.white)),
                                TextSpan(text: 'Screen', style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                        ]),
                        // Online + bell + profile
                        Row(children: [
                          // Online indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isOffline ? Colors.red.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: _isOffline ? Colors.red.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (_, __) => Opacity(
                                  opacity: _isOffline ? 1.0 : _pulseAnimation.value,
                                  child: Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      color: _isOffline ? Colors.red : Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(_isOffline ? 'Offline' : 'Online',
                                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700,
                                  color: _isOffline ? Colors.red : Colors.white)),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          // Notification bell
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(context, PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const NotificationsScreen(),
                                transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 300),
                              ));
                              if (mounted) setState(() => _notificationCount = 0);
                            },
                            child: Stack(clipBehavior: Clip.none, children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                child: Icon(
                                  _notificationCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_rounded,
                                  color: Colors.white, size: 18,
                                ),
                              ),
                              if (_notificationCount > 0)
                                Positioned(
                                  top: -4, right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text('$_notificationCount',
                                      style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ),
                                ),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          // Profile avatar
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [AppColors.greenDark, AppColors.green],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _chwPhoto.isNotEmpty && File(_chwPhoto).existsSync()
                                  ? Image.file(File(_chwPhoto), width: 38, height: 38, fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        _chwName.trim().isEmpty ? 'VS' : _chwName.trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase(),
                                        style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                    ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // â”€â”€ Greeting â”€â”€
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900),
                        children: [
                          TextSpan(
                            text: _now.hour < 12 ? 'Good morning, ' : _now.hour < 17 ? 'Good afternoon, ' : 'Good evening, ',
                            style: const TextStyle(color: Colors.black, fontSize: 22),
                          ),
                          TextSpan(
                            text: (_chwName.isNotEmpty ? _chwName.split(' ').first : 'CHW') + '!',
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // â”€â”€ Location + time row â”€â”€
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _fetchLocation,
                          child: Row(children: [
                            Icon(
                              _locationLabel.contains('retry') || _locationLabel.contains('timeout')
                                  ? Icons.refresh_rounded : Icons.location_on_rounded,
                              size: 12, color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(_locationLabel, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 11,
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            Icon(Icons.access_time_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(_formatTime(_now), style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // â”€â”€ Date row â”€â”€
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(_formatDate(_now), style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 14),
                    // â”€â”€ Sync bar â”€â”€
                    _buildSyncBar(),
                    const SizedBox(height: 12),
                    // â”€â”€ Stats â”€â”€
                    _buildStatsRow(),
                  ],

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRow() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
              colors: [AppColors.greenDark, AppColors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),

          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _chwPhoto.isNotEmpty && File(_chwPhoto).existsSync()
                ? Image.file(
                    File(_chwPhoto),
                    width: 42, height: 42,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      _chwName.trim().isEmpty
                          ? 'VS'
                          : _chwName.trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase(),
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chwName.isNotEmpty ? _chwName : 'VisionScreen User',
                style: GoogleFonts.nunito(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            Text(
                _chwCenter.isNotEmpty ? 'CHW · $_chwCenter' : 'Community Health Worker',
                style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            FutureBuilder<String>(
              future: SharedPreferences.getInstance().then((p) => p.getString('chw_id') ?? 'CHW-000000'),
              builder: (_, snap) {
                final id = snap.data ?? 'CHW-000000';
                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
                  ),
                  child: Text(id,
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFFFD700))),
                );
              },
            ),
          ],
        ),
        const Spacer(),
        // Real-time connectivity indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isOffline
                ? Colors.red.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: _isOffline
                  ? Colors.red.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Opacity(
                  opacity: _isOffline ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isOffline
                          ? Colors.red
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isOffline ? 'Offline' : 'Online',
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _isOffline
                        ? Colors.red
                        : Colors.white),
              ),
            ],
          ),
        ),
        // Notification bell with badge
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, anim, _) => const NotificationsScreen(),
                transitionsBuilder: (_, anim, _, child) {
                  final slide = Tween<Offset>(
                    begin: const Offset(1.0, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic));
                  final fade = Tween<double>(begin: 0.0, end: 1.0)
                      .animate(CurvedAnimation(
                          parent: anim,
                          curve: const Interval(0.0, 0.6,
                              curve: Curves.easeIn)));
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                transitionDuration: const Duration(milliseconds: 380),
              ),
            );
            if (mounted) setState(() => _notificationCount = 0);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bell button
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _notificationCount > 0 ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (context, val, child) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(
                          Colors.white.withOpacity(0.09),
                          const Color(0xFFF59E0B).withOpacity(0.28),
                          val,
                        )!,
                        Color.lerp(
                          Colors.white.withOpacity(0.05),
                          const Color(0xFFEF4444).withOpacity(0.18),
                          val,
                        )!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Color.lerp(
                        Colors.white.withOpacity(0.12),
                        const Color(0xFFF59E0B).withOpacity(0.55),
                        val,
                      )!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity((0.28 * val).clamp(0.0, 1.0)),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    _notificationCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_rounded,
                    color: Color.lerp(
                      Colors.white.withOpacity(0.85),
                      const Color(0xFFF59E0B),
                      val,
                    ),
                    size: 21,
                  ),
                ),
              ),
              // Badge
              if (_notificationCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: 0.88 + (_pulseAnimation.value * 0.12),
                      child: child,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: const Color(0xFF04091A), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.65),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncBar() {
    return GestureDetector(
      onTap: _isSyncing ? null : _doSync,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF97316).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEA580C)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Opacity(
                opacity: _isSyncing ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _isSyncing ? const Color(0xFF22C55E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isSyncing ? 'Syncing...' : '$_unsyncedCount record${_unsyncedCount == 1 ? '' : 's'} pending sync',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
            _isSyncing
                ? const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Colors.white,
                    ),
                  )
                : Text('Sync Now',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }


  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          number: '$_totalScreened',
          label: 'Screened',
          icon: Icons.remove_red_eye_outlined,
          cardColor: const Color(0xFF0EA5E9),
          iconBg: const Color(0xFF0284C7),
        ),
        const SizedBox(width: 6),
        _buildStatCard(
          number: '${_totalScreened - _totalReferred}',
          label: 'Passed',
          icon: Icons.check_circle_outline_rounded,
          cardColor: AppColors.green,
          iconBg: const Color(0xFF27AE60),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          number: '$_totalReferred',
          label: 'Referred',
          icon: Icons.warning_amber_rounded,
          cardColor: const Color(0xFFEF4444),
          iconBg: const Color(0xFFDC2626),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          number: '$_unsyncedCount',
          label: 'Pending',
          icon: Icons.hourglass_top_rounded,
          cardColor: const Color(0xFF8B5CF6),
          iconBg: const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String number,
    required String label,
    required IconData icon,
    required Color cardColor,
    required Color iconBg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 13, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(number,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }



  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _buildOfflineBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                size: 16, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are offline',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E))),
                Text('All data is saved locally. Sync will resume when connected.',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E).withOpacity(0.75))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('SQLite',
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E))),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
          letterSpacing: 1.5,
        )),
    );
  }

  Widget _buildPassRateStrip() {
    final passed = _totalScreened - _totalReferred;
    final passRate = _totalScreened > 0 ? passed / _totalScreened : 0.0;
    final passPercent = (passRate * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.greenDeep, AppColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: passRate),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) => CircularProgressIndicator(
                    value: val,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.green),
                  ),
                ),
                Center(
                  child: Text(
                    _totalScreened == 0 ? 'N/A' : '${passPercent}%',
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pass Rate (All Time)',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  _totalScreened == 0
                      ? 'No screenings yet'
                      : '${passed} passed \u00b7 ${_totalReferred} referred',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${_totalScreened} total',
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {
        'icon': Icons.remove_red_eye_outlined,
        'title': 'New Screening',
        'sub': 'Register & test patient',
        'image': 'asset:—Pngtree—visual acuity_7080163.png',
        'overlayColors': [AppColors.green, const Color(0xFF04091A)],
        'tag': 'START TEST',
      },
      {
        'icon': Icons.groups_outlined,
        'title': 'Bulk Mode',
        'sub': 'Campaign screening',
        'image': 'asset:image.png',
        'overlayColors': [const Color(0xFF0B1530), const Color(0xFF04091A)],
        'tag': 'CAMPAIGN',
      },
      {
        'icon': Icons.school_outlined,
        'title': 'Training',
        'sub': 'Learn the system',
        'image': 'asset:Medical Staff Meeting-800x531.jpg',
        'overlayColors': [const Color(0xFF065F46), const Color(0xFF064E3B)],
        'tag': 'LEARN',
      },
      {
        'icon': Icons.insights_outlined,
        'title': 'Analytics',

        'sub': 'Programme data',
        'image': 'asset:pngwing.com.png',
        'overlayColors': [const Color(0xFF1E3A5F), const Color(0xFF0F172A)],
        'tag': 'INSIGHTS',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: actions.map((a) => _buildActionCard(a)).toList(),
    );
  }

  Widget _buildActionCard(Map a) {
    final accent = (a['overlayColors'] as List<Color>).first;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (a['title'] == 'New Screening') {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NewScreeningScreen(startWithNewPatient: true)),
            ).then((_) => _loadDbStats());
          } else if (a['title'] == 'Bulk Mode') {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BulkModeScreen()),
            ).then((_) => _loadDbStats());
          } else if (a['title'] == 'Training') {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TrainingScreen()));
          } else if (a['title'] == 'Analytics') {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
          }
        },
        splashColor: AppColors.greenHero,
        highlightColor: AppColors.greenHero,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image top half
                Expanded(
                  child: Builder(builder: (_) {
                    final img = a['image'] as String;
                    if (img.startsWith('asset:')) {
                      return Image.asset(
                        img.substring(6),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.greenHero),
                      );
                    }
                    return Image.network(
                      img, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.greenHero),
                    );
                  }),
                ),
                // White bottom info strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.greenHero,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Icon(a['icon'] as IconData,
                            color: AppColors.greenDark, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(a['title'] as String,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark)),
                            Text(a['sub'] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenHero,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Text(a['tag'] as String,
                            style: GoogleFonts.poppins(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenDark,
                                letterSpacing: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRecentPatients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Screenings",
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: 0.1)),
                Text('${_recentScreenings.length} patient${_recentScreenings.length == 1 ? '' : 's'} · ${_formatDate(_now)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400)),
              ],
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientsScreen()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded,
                  size: 13, color: AppColors.green),
              label: Text('See all',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.greenHero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentScreenings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No screenings yet.\nTap the eye button below to start.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted, height: 1.6),
              ),
            ),
          )
        else
          ..._recentScreenings.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final name = r['name'] as String;
            final age = (r['age'] as int?) ?? 0;
            final gender = (r['gender'] as String?) ?? '';
            final outcome = (r['outcome'] as String?) ?? 'pass';
            final od = (r['od_snellen'] as String?) ?? '—';
            final os = (r['os_snellen'] as String?) ?? '—';
            final ou = (r['ou_near_snellen'] as String?) ?? '—';
            final pid = (r['patient_id'] as String?) ?? '';
            final ageGroup = age < 18 ? 'child' : age > 60 ? 'elderly' : 'adult';
            final photoPath = (r['photo_path'] as String?) ?? '';
            final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join();
            String timeLabel;
            try {
              final dt = DateTime.parse(r['screening_date'] as String);
              final diff = DateTime.now().difference(dt);
              timeLabel = diff.inMinutes < 60 ? '${diff.inMinutes}m ago' : '${diff.inHours}hr ago';
            } catch (_) {
              timeLabel = 'Today';
            }
            return Padding(
              padding: EdgeInsets.only(bottom: i < _recentScreenings.length - 1 ? 8 : 0),
              child: _buildPatientCard(
                photoPath, outcome == 'refer' ? ['#EF4444', '#F97316'] : outcome == 'pass' ? ['#0D9488', '#14B8A6'] : ['#F59E0B', '#FBBF24'], initials, name,
                '$gender · $age yrs', 'OD $od', 'OS $os', 'OU $ou',
                timeLabel, outcome, pid, ageGroup,
              ),
            );
          }),
      ],
    );
  }

    Widget _buildPatientCard(
    String photoUrl,
    List<String> gradientHex,
    String initials,
    String name,
    String demographic,
    String od, String os, String ou,
    String time,
    String outcome,
    String id,
    String ageGroup,
  ) {
    final Color c1 = Color(int.parse('0xFF${gradientHex[0].replaceAll('#', '')}'));
    final Color c2 = Color(int.parse('0xFF${gradientHex[1].replaceAll('#', '')}'));
    final accentColor = outcome == 'pass'
        ? const Color(0xFF22C55E)
        : outcome == 'refer'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final badgeLabel = outcome == 'pass' ? 'Pass' : outcome == 'refer' ? 'Refer' : 'Pending';
    final badgeBg = outcome == 'pass'
        ? const Color(0xFFDCFCE7)
        : outcome == 'refer'
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFE0F2FE);
    final badgeText = outcome == 'pass'
        ? const Color(0xFF15803D)
        : outcome == 'refer'
            ? const Color(0xFF991B1B)
            : const Color(0xFF0369A1);
    final badgeIcon = outcome == 'pass'
        ? Icons.check_circle_rounded
        : outcome == 'refer'
            ? Icons.warning_rounded
            : Icons.schedule_rounded;
    final ageColor = ageGroup == 'child'
        ? const Color(0xFF3B82F6)
        : ageGroup == 'elderly'
            ? const Color(0xFFEF4444)
            : AppColors.green;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        highlightColor: const Color(0xFFF0F4F7),
        splashColor: const Color(0xFFDDE4EC),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accent bar
                    Container(
                      width: 4, height: 72,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: c2.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                         child: photoUrl.isNotEmpty && File(photoUrl).existsSync()
                             ? Image.file(File(photoUrl), fit: BoxFit.cover, width: 50, height: 50)
                             : Container(
                                 decoration: BoxDecoration(
                                   gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                   borderRadius: BorderRadius.circular(14),
                                 ),
                                 child: Center(child: Text(initials, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
                               ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: ageColor.withOpacity(0.1), borderRadius: BorderRadius.circular(99), border: Border.all(color: ageColor.withOpacity(0.25))),
                                child: Text(ageGroup[0].toUpperCase() + ageGroup.substring(1), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: ageColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF8FA0B4)),
                              const SizedBox(width: 4),
                               Flexible(child: Text(demographic, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (outcome != 'pending')
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              _homeVaPill(od, outcome),
                              const SizedBox(width: 4),
                              _homeVaPill(os, outcome),
                              const SizedBox(width: 4),
                              _homeVaPill(ou, outcome),
                            ])
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.hourglass_top_rounded, size: 11, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 5),
                                Text('Awaiting screening', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                              ]),
                            ),
                        ],
                      ),
                    ),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(99), border: Border.all(color: accentColor.withOpacity(0.25))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(badgeIcon, size: 10, color: accentColor),
                        const SizedBox(width: 3),
                        Text(badgeLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor)),
                      ]),
                    ),
                  ],
                ),
              ),
              // Bottom strip
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                  border: Border(top: BorderSide(color: accentColor.withOpacity(0.12))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 11, color: Color(0xFF8FA0B4)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(id, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF8FA0B4)),
                    const SizedBox(width: 4),
                    Text(time, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text('View →', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeVaPill(String value, String outcome) {
    final isBad = outcome == 'refer' && value != '6/6' && value != '6/9' && value != '6/12';
    final fg = isBad ? const Color(0xFFEF4444) : AppColors.greenDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(value, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildReferralFollowUps() {
    final overdue = _referredPatients.where((r) => r['referral_status'] == 'overdue').length;
    final pending = _referredPatients.where((r) =>
        r['referral_status'] == 'pending' || r['referral_status'] == 'notified').length;
    final dueCount = overdue + pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Referral Follow-Ups',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: AppColors.textDark, letterSpacing: 0.1)),
                Text(dueCount > 0 ? '$dueCount due · Action required' : 'All up to date',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: dueCount > 0 ? const Color(0xFFEF4444) : AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsScreen())),
              icon: const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.green),
              label: Text('View all', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.greenDark, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.greenHero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_referredPatients.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('No referrals yet.',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),
            ),
          )
        else
          ..._referredPatients.take(3).map((r) {
            final name = r['name'] as String;
            final campaignId = (r['campaign_id'] as String?) ?? '';
            final isBulk = campaignId.isNotEmpty;
            final age = (r['age'] as int?) ?? 0;
            final gender = (r['gender'] as String?) ?? '';
            final facility = ((r['referral_facility'] as String?) ?? '').isEmpty
                ? 'No facility set'
                : r['referral_facility'] as String;
            final status = (r['referral_status'] as String?) ?? 'pending';
            final photoPath = (r['photo_path'] as String?) ?? '';
            final od = (r['od_snellen'] as String?) ?? '—';
            final os = (r['os_snellen'] as String?) ?? '—';
            final appointmentDate = r['appointment_date'] as String?;
            String dueLabel = 'No date set';
            if (appointmentDate != null && appointmentDate.isNotEmpty) {
              try {
                final dt = DateTime.parse(appointmentDate);
                dueLabel = 'Due ${dt.day}/${dt.month}/${dt.year}';
              } catch (_) {}
            }
            final statusColor = status == 'overdue'
                ? const Color(0xFFEF4444)
                : status == 'completed' ? const Color(0xFF22C55E)
                : status == 'attended' ? AppColors.green
                : status == 'notified' ? const Color(0xFF3B82F6)
                : const Color(0xFFF59E0B);
            final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildReferralCard(
                photoPath, statusColor, name, '$gender · $age yrs',
                facility, dueLabel,
                status[0].toUpperCase() + status.substring(1),
                statusColor.withOpacity(0.15), statusColor,
                status == 'overdue' ? Icons.error_rounded : Icons.notifications_active_rounded,
                od, os, initials,
                (r['screening_id'] as int? ?? 0),
              ),
            );
          }),
      ],
    );
  }

  void _showUpdateStatusSheet(BuildContext ctx, int screeningId, String currentStatus, String patientName) {
    final statuses = [
      {'value': 'pending',   'label': 'Pending',   'icon': Icons.schedule_rounded,             'color': const Color(0xFFF59E0B)},
      {'value': 'notified',  'label': 'Notified',  'icon': Icons.notifications_active_rounded, 'color': const Color(0xFF3B82F6)},
      {'value': 'attended',  'label': 'Attended',  'icon': Icons.check_circle_outline_rounded, 'color': AppColors.green},
      {'value': 'completed', 'label': 'Completed', 'icon': Icons.check_circle_rounded,         'color': const Color(0xFF22C55E)},
      {'value': 'overdue',   'label': 'Overdue',   'icon': Icons.error_rounded,                'color': const Color(0xFFEF4444)},
      {'value': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel_rounded,               'color': Colors.grey},
    ];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDDE4EC), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.update_rounded, color: AppColors.green, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Update Referral Status', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text(patientName, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
              ])),
            ]),
            const SizedBox(height: 20),
            ...statuses.map((st) {
              final val = st['value'] as String;
              final isActive = currentStatus == val;
              final color = st['color'] as Color;
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await DatabaseHelper.instance.updateReferralStatus(screeningId, val);
                  await _loadDbStats();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Status updated to ' + (st['label'] as String),
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                    backgroundColor: color, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isActive ? color.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isActive ? color : const Color(0xFFEEF2F6), width: isActive ? 2 : 1.5),
                  ),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(st['icon'] as IconData, size: 18, color: color)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(st['label'] as String,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600,
                            color: isActive ? color : AppColors.textDark))),
                    if (isActive) Icon(Icons.check_circle_rounded, color: color, size: 20),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard(
    String photoPath,
    Color avatarColor,
    String name,
    String demographic,
    String facility,
    String dueDate,
    String status,
    Color badgeBg,
    Color accentColor,
    IconData statusIcon,
    String od,
    String os,
    String initials,
    int screeningId,
  ) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        highlightColor: const Color(0xFFF0F4F7),
        splashColor: const Color(0xFFDDE4EC),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top section
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: avatarColor.withOpacity(0.4), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: photoPath.isNotEmpty && File(photoPath).existsSync()
                            ? Image.file(File(photoPath), fit: BoxFit.cover, width: 48, height: 48)
                            : Container(
                                color: avatarColor.withOpacity(0.15),
                                child: Center(child: Text(initials,
                                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: avatarColor))),
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
                              Flexible(
                                child: Text(name,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                              ),
                              const SizedBox(width: 6),
                              Text(demographic,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.local_hospital_rounded,
                                  size: 11, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(facility,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            _homeVaPill(od, 'refer'),
                            const SizedBox(width: 5),
                            _homeVaPill(os, 'refer'),

                            
                          ]),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: accentColor.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 10, color: accentColor),
                          const SizedBox(width: 3),
                          Text(status,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom action bar
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.06),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                  border: Border(
                      top: BorderSide(
                          color: accentColor.withOpacity(0.15), width: 1)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: accentColor),
                    const SizedBox(width: 6),
                    Text(dueDate,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showUpdateStatusSheet(
                        context,
                        screeningId,
                        (status.toLowerCase()),
                        name,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: accentColor.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Update Status',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor)),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_rounded, size: 11, color: accentColor),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  final List<Map<String, dynamic>> _notifications = [
    {'icon': Icons.warning_rounded, 'color': Color(0xFFEF4444), 'title': 'Referral Overdue', 'body': 'Okello James has not attended Mulago Hospital.', 'time': '2 min ago', 'read': false, 'tag': 'URGENT'},
    {'icon': Icons.person_add_rounded, 'color': AppColors.green, 'title': 'New Patient Registered', 'body': 'Mugisha Wilson is awaiting screening.', 'time': '15 min ago', 'read': false, 'tag': 'PATIENT'},
    {'icon': Icons.sync_rounded, 'color': Color(0xFF38BDF8), 'title': 'Sync Pending', 'body': '3 records waiting to sync to MongoDB Atlas.', 'time': '1 hr ago', 'read': false, 'tag': 'SYNC'},
    {'icon': Icons.check_circle_rounded, 'color': Color(0xFF22C55E), 'title': 'Screening Completed', 'body': 'Akello Mercy passed. OD 6/6, OS 6/9.', 'time': '2 hr ago', 'read': true, 'tag': 'RESULT'},
    {'icon': Icons.notifications_active_rounded, 'color': Color(0xFF8B5CF6), 'title': 'Appointment Reminder', 'body': 'Byaruhanga Sam â€” Kampala Eye Clinic, 2 Apr.', 'time': '3 hr ago', 'read': true, 'tag': 'REMINDER'},
    {'icon': Icons.assignment_rounded, 'color': Color(0xFFF59E0B), 'title': 'Referral Generated', 'body': 'Referral created for Okello James â€” Mulago.', 'time': 'Yesterday', 'read': true, 'tag': 'REFERRAL'},
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).length;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE4EC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: GoogleFonts.nunito(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      Text(unread > 0 ? '$unread unread' : 'All caught up âœ“',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textMuted,
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                  const Spacer(),
                  if (unread > 0)
                    GestureDetector(
                      onTap: () => setState(() {
                        for (final n in _notifications) {
                          n['read'] = true;
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppColors.green.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.done_all_rounded, size: 13, color: AppColors.green),
                            const SizedBox(width: 5),
                            Text('Mark all read',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: AppColors.green)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEF2F6)),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _buildCard(i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final n = _notifications[index];
    final isRead = n['read'] as bool;
    final color = n['color'] as Color;
    return Dismissible(
      key: Key('n_${n['title']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => setState(() => _notifications.removeAt(index)),
      child: GestureDetector(
        onTap: () => setState(() => _notifications[index]['read'] = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? const Color(0xFFEEF2F6) : color.withOpacity(0.25),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isRead ? Colors.black.withOpacity(0.03) : color.withOpacity(0.1),
                blurRadius: isRead ? 4 : 12,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(isRead ? 0.08 : 0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withOpacity(isRead ? 0.1 : 0.3)),
                ),
                child: Icon(n['icon'] as IconData,
                    color: color.withOpacity(isRead ? 0.5 : 1.0), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n['title'] as String,
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                  color: isRead ? AppColors.textMuted : AppColors.textDark)),
                        ),
                        if (!isRead)
                          Container(
                            width: 7, height: 7,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(n['body'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textMuted, height: 1.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 10, color: const Color(0xFFB0BEC5)),
                        const SizedBox(width: 3),
                        Text(n['time'] as String,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: const Color(0xFFB0BEC5),
                                fontWeight: FontWeight.w400)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(n['tag'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 8, fontWeight: FontWeight.w700,
                                  color: color, letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> tips;
  const _TipDialogContent({required this.tips});
  @override
  State<_TipDialogContent> createState() => _TipDialogContentState();
}

class _TipDialogContentState extends State<_TipDialogContent> {
  int _idx = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _idx = (_idx + 1) % widget.tips.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tips[_idx];
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo header
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: ClipRRect(
                key: ValueKey('img$_idx'),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      tip['image'] as String,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 160,
                        color: (tip['color'] as Color).withOpacity(0.15),
                        child: Icon(tip['icon'] as IconData,
                            size: 48, color: tip['color'] as Color),
                      ),
                    ),
                    // Dark gradient overlay
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                    // Color tint
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (tip['color'] as Color).withOpacity(0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Icon badge + label
                    Positioned(
                      bottom: 14,
                      left: 16,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5),
                            ),
                            child: Icon(tip['icon'] as IconData,
                                size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (tip['color'] as Color).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('CLINICAL TIP OF THE DAY',
                                style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.3)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sliding tip text
            SizedBox(
              height: 110,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: const Offset(1.0, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic));
                  return ClipRect(
                    child: SlideTransition(
                      position: slide,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                  );
                },
                child: Padding(
                  key: ValueKey('text$_idx'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 16),
                  child: Text(
                    tip['text'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        height: 1.6),
                  ),
                ),
              ),
            ),
            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.tips.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _idx ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _idx
                        ? tip['color'] as Color
                        : const Color(0xFFDDE4EC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text("Got it, let's screen!",
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HomeWaveClipper old) => false;
}

class _HomeDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HomeDotPainter old) => false;
}
