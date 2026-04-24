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
import 'training_screen.dart';
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

  int _totalScreened = 0;
  int _totalReferred = 0;
  int _unsyncedCount = 0;
  List<Map<String, dynamic>> _recentScreenings = [];
  List<Map<String, dynamic>> _referredPatients = [];

  final List<Map<String, dynamic>> _tips = [
    {'icon': Icons.wb_sunny_rounded, 'color': Color(0xFFF59E0B), 'text': 'Ensure adequate room lighting before starting a vision test.', 'image': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400&q=80'},
    {'icon': Icons.straighten_rounded, 'color': Color(0xFF0D9488), 'text': 'Always confirm the patient is exactly 3 metres from the screen.', 'image': 'https://images.unsplash.com/photo-1581595220892-b0739db3ba8c?w=400&q=80'},
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
              style: GoogleFonts.ibmPlexSans(fontSize: 12)),
          backgroundColor: const Color(0xFF0D9488),
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF0D9488),
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
                  color: const Color(0xFF0D9488).withOpacity(0.08),
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
                        color: const Color(0xFF0D9488).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF0D9488).withOpacity(0.3),
                            width: 2),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Color(0xFF0D9488), size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text('Location Permission Required',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.barlow(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A2A3D))),
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
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5E7291),
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
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
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
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8FA0B4))),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 38, 18, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF04091A), Color(0xFF0B1530)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserRow(),
          const SizedBox(height: 6),
          Text(
            'Ready to screen,',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            "let's go!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              color: const Color(0xFF5EEAD4),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          // Location row â€” tappable to retry
          GestureDetector(
            onTap: _fetchLocation,
            child: Row(
              children: [
                Icon(
                  _locationLabel.contains('retry') || _locationLabel.contains('timeout')
                      ? Icons.refresh_rounded
                      : Icons.location_on_rounded,
                  size: 11,
                  color: const Color(0x8C5EEAD4),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _locationLabel,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: const Color(0x8C5EEAD4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Date and time row
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 11, color: const Color(0x8C5EEAD4)),
              const SizedBox(width: 4),
              Text(
                _formatDate(_now),
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: const Color(0x8C5EEAD4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 10, color: const Color(0xFF5EEAD4)),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_now),
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5EEAD4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSyncBar(),
          const SizedBox(height: 8),
          _buildStatsRow(),
          const SizedBox(height: 10),
        ],
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
            border: Border.all(
                color: const Color(0xFF0D9488).withOpacity(0.4), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  ),
                ),
                child: Center(
                  child: Text('NM',
                      style: GoogleFonts.ibmPlexSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nakato Mary',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            Text('CHW Â· Nakawa HC III',
                style: GoogleFonts.inter(
                    color: const Color(0x995EEAD4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
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
                ? const Color(0xFFEF4444).withOpacity(0.2)
                : const Color(0xFF22C55E).withOpacity(0.15),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: _isOffline
                  ? const Color(0xFFEF4444).withOpacity(0.5)
                  : const Color(0xFF22C55E).withOpacity(0.4),
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
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isOffline ? 'Offline' : 'Online',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _isOffline
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E)),
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
                tween: Tween(begin: 0, end: _notificationCount > 0 ? 1.0 : 0.0),
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
                        color: const Color(0xFFF59E0B).withOpacity(0.28 * val),
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
                        style: GoogleFonts.inter(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated pulsing dot
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Opacity(
                opacity: _isSyncing ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isSyncing
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isSyncing
                    ? 'Syncing to MongoDB Atlas...'
                    : '$_unsyncedCount record${_unsyncedCount == 1 ? '' : 's'} pending sync',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xCC5EEAD4),
                    fontWeight: FontWeight.w500),
              ),
            ),
            _isSyncing
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF5EEAD4),
                    ),
                  )
                : Text('Sync Now',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF5EEAD4),
                        fontWeight: FontWeight.w700)),
          ],
        ),
          ),
        ),
      ),
    );
  }

    Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('$_totalScreened', 'Screened', 'Total', const Color(0xFF5EEAD4)),
        const SizedBox(width: 8),
        _buildStatCard('$_totalReferred', 'Referrals', 'Need follow-up', const Color(0xFFF59E0B)),
        const SizedBox(width: 8),
        _buildStatCard('$_unsyncedCount', 'Unsynced', 'Pending upload', const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _buildStatCard(
      String number, String label, String change, Color changeColor) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(number,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0x8C5EEAD4),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0)),
            const SizedBox(height: 3),
            Text(change,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: changeColor,
                    fontWeight: FontWeight.w600)),
          ],
        ),
          ),
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
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E))),
                Text('All data is saved locally. Sync will resume when connected.',
                    style: GoogleFonts.ibmPlexSans(
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
                style: GoogleFonts.ibmPlexSans(
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
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A2A3D),
            letterSpacing: 1.8,
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
          colors: [Color(0xFF0D3D38), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.25),
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
                        Color(0xFF5EEAD4)),
                  ),
                ),
                Center(
                  child: Text(
                    _totalScreened == 0 ? 'N/A' : '${passPercent}%',
                    style: GoogleFonts.spaceGrotesk(
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
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  _totalScreened == 0
                      ? 'No screenings yet'
                      : '${passed} passed \u00b7 ${_totalReferred} referred',
                  style: GoogleFonts.inter(
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
              style: GoogleFonts.spaceGrotesk(
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
        'image': 'https://images.unsplash.com/photo-1638202993928-7267aad84c31?w=400&q=80',
        'overlayColors': [const Color(0xFF0D9488), const Color(0xFF04091A)],
        'tag': 'START TEST',
      },
      {
        'icon': Icons.groups_outlined,
        'title': 'Bulk Mode',
        'sub': 'Campaign screening',
        'image': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400&q=80',
        'overlayColors': [const Color(0xFF0B1530), const Color(0xFF04091A)],
        'tag': 'CAMPAIGN',
      },
      {
        'icon': Icons.school_outlined,
        'title': 'Training',
        'sub': 'Learn the system',
        'image': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400&q=80',
        'overlayColors': [const Color(0xFF065F46), const Color(0xFF064E3B)],
        'tag': 'LEARN',
      },
      {
        'icon': Icons.insights_outlined,
        'title': 'Analytics',
        'sub': 'Programme data',
        'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80',
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
      childAspectRatio: 1.7,
      children: actions.map((a) => _buildActionCard(a)).toList(),
    );
  }

  Widget _buildActionCard(Map a) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (a['title'] == 'New Screening') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewScreeningScreen(startWithNewPatient: true)),
            ).then((_) => _loadDbStats());
          } else if (a['title'] == 'Bulk Mode') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BulkModeScreen()),
            ).then((_) => _loadDbStats());
          } else if (a['title'] == 'Training') {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TrainingScreen()));
          } else if (a['title'] == 'Analytics') {
            Navigator.pushNamed(context, '/analytics');
          }
        },
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                a['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: (a['overlayColors'] as List<Color>).first,
                ),
              ),
              // Dark gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.78),
                    ],
                  ),
                ),
              ),
              // Tint overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (a['overlayColors'] as List<Color>)[0].withOpacity(0.35),
                      (a['overlayColors'] as List<Color>)[1].withOpacity(0.55),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: icon box + tag chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1),
                          ),
                          child: Icon(a['icon'] as IconData,
                              color: Colors.white, size: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1),
                          ),
                          child: Text(
                            a['tag'] as String,
                            style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.2),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bottom: title + subtitle + arrow
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['title'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.1,
                                      height: 1.1)),
                              const SizedBox(height: 3),
                              Text(a['sub'] as String,
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.65))),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 11),
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
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2A3D),
                        letterSpacing: 0.1)),
                Text('${_recentScreenings.length} patient${_recentScreenings.length == 1 ? '' : 's'} · ${_formatDate(_now)}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8FA0B4),
                        fontWeight: FontWeight.w400)),
              ],
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientsScreen()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded,
                  size: 13, color: Color(0xFF0D9488)),
              label: Text('See all',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF0D9488),
                      fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488).withOpacity(0.08),
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
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4), height: 1.6),
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
            : const Color(0xFF0D9488);

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
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
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
                                 child: Center(child: Text(initials, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
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
                              Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A2A3D)))),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: ageColor.withOpacity(0.1), borderRadius: BorderRadius.circular(99), border: Border.all(color: ageColor.withOpacity(0.25))),
                                child: Text(ageGroup[0].toUpperCase() + ageGroup.substring(1), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: ageColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF8FA0B4)),
                              const SizedBox(width: 4),
                              Text(demographic, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (outcome != 'pending')
                            Row(children: [
                              _homeVaPill(od, outcome),
                              const SizedBox(width: 5),
                              _homeVaPill(os, outcome),
                              const SizedBox(width: 5),
                              _homeVaPill(ou, outcome),
                            ])
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.hourglass_top_rounded, size: 11, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 5),
                                Text('Awaiting screening', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                              ]),
                            ),
                        ],
                      ),
                    ),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(99), border: Border.all(color: accentColor.withOpacity(0.25))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(badgeIcon, size: 11, color: accentColor),
                        const SizedBox(width: 4),
                        Text(badgeLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor)),
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
                    const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF8FA0B4)),
                    const SizedBox(width: 5),
                    Text(id, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4), fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF8FA0B4)),
                    const SizedBox(width: 4),
                    Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8FA0B4), fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    Text('View →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor)),
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
    final fg = isBad ? const Color(0xFFEF4444) : const Color(0xFF0D9488);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
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
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2A3D), letterSpacing: 0.1)),
                Text(dueCount > 0 ? '$dueCount due · Action required' : 'All up to date',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: dueCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF8FA0B4),
                        fontWeight: FontWeight.w500)),
              ],
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsScreen())),
              icon: const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF0D9488)),
              label: Text('View all', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0D9488), fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488).withOpacity(0.08),
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
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8FA0B4))),
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
                : status == 'attended' ? const Color(0xFF0D9488)
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
              ),
            );
          }),
      ],
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
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: avatarColor))),
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
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A2A3D))),
                              ),
                              const SizedBox(width: 6),
                              Text(demographic,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF8FA0B4))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.local_hospital_rounded,
                                  size: 11, color: const Color(0xFF8FA0B4)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(facility,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF5E7291))),
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
                              style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor)),
                    const Spacer(),
                    Text('Update Status →',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: accentColor)),
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
    {'icon': Icons.person_add_rounded, 'color': Color(0xFF0D9488), 'title': 'New Patient Registered', 'body': 'Mugisha Wilson is awaiting screening.', 'time': '15 min ago', 'read': false, 'tag': 'PATIENT'},
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
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A2A3D))),
                      Text(unread > 0 ? '$unread unread' : 'All caught up âœ“',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF8FA0B4),
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
                          color: const Color(0xFF0D9488).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.done_all_rounded, size: 13, color: Color(0xFF0D9488)),
                            const SizedBox(width: 5),
                            Text('Mark all read',
                                style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D9488))),
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
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                  color: isRead ? const Color(0xFF5E7291) : const Color(0xFF1A2A3D))),
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
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF8FA0B4), height: 1.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 10, color: const Color(0xFFB0BEC5)),
                        const SizedBox(width: 3),
                        Text(n['time'] as String,
                            style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A2A3D),
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
                    backgroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text("Got it, let's screen!",
                      style: GoogleFonts.inter(
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
