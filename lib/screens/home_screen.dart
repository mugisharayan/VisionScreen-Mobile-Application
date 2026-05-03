import 'dart:async';
import 'dart:async' show TimeoutException;
import 'dart:io';
import 'dart:math';
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
import '../repositories/screening_repository.dart';
import '../utils/app_theme.dart';
import '../widgets/vs_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  // ── Data ──────────────────────────────────────────────────
  String _chwName     = '';
  String _chwCenter   = '';
  String _chwDistrict = '';
  String _chwPhoto    = '';
  int _totalScreened  = 0;
  int _totalReferred  = 0;
  int _unsyncedCount  = 0;
  int _notificationCount = 0;
  bool _isSyncing     = false;
  List<Map<String, dynamic>> _recentScreenings = [];
  List<Map<String, dynamic>> _referredPatients = [];

  // ── UI state ──────────────────────────────────────────────
  bool _isOffline = false;
  String _locationLabel = 'Detecting location...';
  DateTime _now = DateTime.now();

  // ── Subscriptions / timers ────────────────────────────────
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  late Timer _clockTimer;

  // ── Animations ────────────────────────────────────────────
  // Pulse for online dot
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  // Header entry (slide + fade)
  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerOpacity;
  late final Animation<Offset>   _headerSlide;

  // Stats counter (number roll-up)
  late final AnimationController _statsCtrl;
  late final Animation<double>   _statsAnim;

  // Card stagger (recent list)
  late final AnimationController _cardCtrl;

  // Sync spin
  late final AnimationController _syncCtrl;

  // Tips carousel auto-scroll
  int _tipIndex = 0;
  Timer? _tipTimer;

  static const _tips = [
    _TipData(Icons.wb_sunny_rounded,    VsColors.amber,   'Ensure adequate room lighting before starting a vision test.'),
    _TipData(Icons.straighten_rounded,  VsColors.emerald, 'Always confirm the patient is exactly 3 metres from the screen.'),
    _TipData(Icons.remove_red_eye_rounded, VsColors.sky,  'Test each eye separately — cover one eye completely before testing the other.'),
    _TipData(Icons.elderly_rounded,     VsColors.brand,   'For elderly patients, apply the 6/18 threshold — not the adult 6/12 standard.'),
    _TipData(Icons.child_care_rounded,  VsColors.violet,  'Children may need encouragement — demonstrate the E direction yourself first.'),
    _TipData(Icons.visibility_off_rounded, VsColors.rose, 'Ask patients to remove glasses before the unaided vision test begins.'),
  ];

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Pulse
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Header entry
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    // Stats roll-up
    _statsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _statsAnim = CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOutCubic);

    // Card stagger
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    // Sync spin
    _syncCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();

    // Clock
    _clockTimer = Timer.periodic(const Duration(seconds: 1),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });

    // Tips carousel
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    });

    // Connectivity
    Connectivity().checkConnectivity().then((r) {
      if (mounted) setState(() => _isOffline = r.every((x) => x == ConnectivityResult.none));
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) setState(() => _isOffline = r.every((x) => x == ConnectivityResult.none));
    });

    // Load data then animate
    _loadAll();
    _fetchLocation();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadChwProfile(), _loadDbStats()]);
    if (mounted) {
      _headerCtrl.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _statsCtrl.forward();
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _cardCtrl.forward();
      });
    }
  }

  Future<void> _loadChwProfile() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _chwName     = p.getString('chw_name')    ?? '';
      _chwCenter   = p.getString('chw_center')  ?? '';
      _chwDistrict = p.getString('chw_district') ?? '';
      _chwPhoto    = p.getString('chw_photo')    ?? '';
    });
  }

  Future<void> _loadDbStats() async {
    final sr = ScreeningRepository.instance;
    final outcomes  = await sr.getOutcomeCounts();
    final unsynced  = await sr.getUnsyncedCount();
    final recent    = await sr.getRecentScreeningsWithPatient(limit: 4);
    final referred  = await sr.getReferredPatients();
    final notifs    = await sr.getNotifications();
    if (!mounted) return;
    setState(() {
      _totalScreened    = (outcomes['pass'] ?? 0) + (outcomes['refer'] ?? 0);
      _totalReferred    = outcomes['refer'] ?? 0;
      _unsyncedCount    = unsynced;
      _recentScreenings = recent;
      _referredPatients = referred;
      _notificationCount = notifs.where((n) => n['read'] == false).length;
    });
  }

  Future<void> _onRefresh() async {
    _statsCtrl.forward(from: 0);
    _cardCtrl.forward(from: 0);
    await _loadAll();
  }

  Future<void> _doSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sync complete!',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      backgroundColor: VsColors.emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _fetchLocation() async {
    try {
      final ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) { if (mounted) setState(() => _locationLabel = 'Enable GPS'); return; }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLabel = 'Location denied');
        return;
      }
      if (mounted) setState(() => _locationLabel = 'Detecting...');
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _locationLabel =
          '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}');
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude)
            .timeout(const Duration(seconds: 6));
        if (marks.isNotEmpty && mounted) {
          final parts = [marks.first.subLocality, marks.first.locality, marks.first.administrativeArea]
              .where((s) => s != null && s!.isNotEmpty).toList();
          if (parts.isNotEmpty) setState(() => _locationLabel = parts.join(', '));
        }
      } catch (_) {}
    } on TimeoutException {
      if (mounted) setState(() => _locationLabel = 'GPS timeout');
    } catch (_) {
      if (mounted) setState(() => _locationLabel = 'Tap to retry');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _headerCtrl.dispose();
    _statsCtrl.dispose();
    _cardCtrl.dispose();
    _syncCtrl.dispose();
    _clockTimer.cancel();
    _tipTimer?.cancel();
    _connectivitySub.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────
  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName =>
      _chwName.trim().isEmpty ? 'CHW' : _chwName.trim().split(' ').first;

  String get _initials => _chwName.trim().isEmpty
      ? 'VS'
      : _chwName.trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase();

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const d = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${d[dt.weekday - 1]}, ${dt.day} ${m[dt.month - 1]}';
  }

  String _timeAgo(String iso) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return 'Today'; }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VsColors.scaffold,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: VsColors.brand,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            // Offline banner
            if (_isOffline)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildOfflineBanner(),
                ),
              ),
            // Sync banner (only when unsynced)
            if (_unsyncedCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildSyncBanner(),
                ),
              ),
            // Body content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildImpactBanner(),
                  const SizedBox(height: 12),
                  _buildSectionHeader('Quick Actions', null),
                  _buildActionGrid(),
                  const SizedBox(height: 20),
                  _buildTipCard(),
                  const SizedBox(height: 20),
                  _buildSectionHeader("Today's Screenings",
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PatientsScreen())),
                        child: Text('See all',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: VsColors.brand,
                                fontWeight: FontWeight.w600)),
                      )),
                  const SizedBox(height: 10),
                  _buildRecentList(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Referral Follow-Ups',
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PatientsScreen())),
                        child: Text('View all',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: VsColors.brand,
                                fontWeight: FontWeight.w600)),
                      )),
                  const SizedBox(height: 10),
                  _buildReferralList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerOpacity,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          decoration: const BoxDecoration(
            gradient: VsGradients.hero,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Dot pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: CustomPaint(painter: _DotPainter()),
                ),
              ),
              // Decorative arcs
              Positioned(top: -60, right: -60,
                child: Container(width: 220, height: 220,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1)))),
              Positioned(top: -20, right: -20,
                child: Container(width: 130, height: 130,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1)))),

              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar ──
                      Row(
                        children: [
                          // Logo wordmark
                          VsLogoWordmark(
                              logoSize: 32, color: Colors.white, fontSize: 17),
                          const Spacer(),
                          // Online pill
                          _buildOnlinePill(),
                          const SizedBox(width: 8),
                          // Sync button
                          _buildSyncButton(),
                          const SizedBox(width: 8),
                          // Notification bell
                          _buildNotifBell(),
                          const SizedBox(width: 8),
                          // Avatar
                          _buildAvatar(),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Greeting + illustration row ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_greeting,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text('$_firstName 👋',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.1)),
                                const SizedBox(height: 8),
                                // Location + time
                                Row(children: [
                                  GestureDetector(
                                    onTap: _fetchLocation,
                                    child: Row(children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 12, color: Colors.white.withValues(alpha: 0.8)),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 140),
                                        child: Text(_locationLabel,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.access_time_rounded,
                                          size: 10, color: Colors.white.withValues(alpha: 0.9)),
                                      const SizedBox(width: 4),
                                      Text(_fmtTime(_now),
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ]),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 11, color: Colors.white.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Text(_fmtDate(_now),
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500)),
                                ]),
                              ],
                            ),
                          ),
                          // Sight Mark illustration (right side of header)
                          _buildHeaderIllustration(),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Stats row ──
                      _buildStatsRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlinePill() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isOffline
            ? VsColors.rose.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: _isOffline
              ? VsColors.rose.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _isOffline ? 1.0 : _pulseAnim.value,
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _isOffline ? VsColors.rose : Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(_isOffline ? 'Offline' : 'Online',
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _isOffline ? VsColors.rose : Colors.white)),
      ]),
    );
  }

  Widget _buildSyncButton() {
    return GestureDetector(
      onTap: _isSyncing ? null : _doSync,
      child: AnimatedBuilder(
        animation: _syncCtrl,
        builder: (_, child) => Transform.rotate(
          angle: _isSyncing ? _syncCtrl.value * 2 * 3.14159 : 0,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _unsyncedCount > 0
                ? VsColors.amber.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _unsyncedCount > 0
                  ? VsColors.amber.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _isSyncing
                    ? Icons.sync_rounded
                    : _unsyncedCount > 0
                        ? Icons.cloud_upload_rounded
                        : Icons.cloud_done_rounded,
                color: _unsyncedCount > 0 ? VsColors.amber : Colors.white,
                size: 18,
              ),
              // Badge showing unsynced count
              if (_unsyncedCount > 0 && !_isSyncing)
                Positioned(
                  top: 2, right: 2,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: VsColors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: VsColors.brandDeep, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifBell() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const NotificationsScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ));
        if (mounted) setState(() => _notificationCount = 0);
      },
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(
            _notificationCount > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_rounded,
            color: Colors.white, size: 18),
        ),
        if (_notificationCount > 0)
          Positioned(
            top: -5, right: -5,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: 0.9 + _pulseAnim.value * 0.1, child: child),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VsColors.rose,
                  shape: BoxShape.circle,
                  border: Border.all(color: VsColors.brandDeep, width: 1.5),
                ),
                child: Text('$_notificationCount',
                    style: GoogleFonts.inter(
                        fontSize: 8, fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [VsColors.brandLight, Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _chwPhoto.isNotEmpty && File(_chwPhoto).existsSync()
            ? Image.file(File(_chwPhoto), width: 38, height: 38, fit: BoxFit.cover)
            : Center(
                child: Text(_initials,
                    style: GoogleFonts.plusJakartaSans(
                        color: VsColors.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
      ),
    );
  }

  Widget _buildHeaderIllustration() {
    return SizedBox(
      width: 90, height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 90 * (0.9 + _pulseAnim.value * 0.1),
              height: 90 * (0.9 + _pulseAnim.value * 0.1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15 * _pulseAnim.value),
                    width: 1),
              ),
            ),
          ),
          // Inner ring
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
          ),
          // Logo
          const VsLogoAnimated(size: 44, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return AnimatedBuilder(
      animation: _statsAnim,
      builder: (_, __) {
        final t = _statsAnim.value;
        return Row(
          children: [
            _statCard(
              label: 'Screened',
              value: (_totalScreened * t).round(),
              icon: Icons.remove_red_eye_rounded,
              color: VsColors.sky,
              bg: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 8),
            _statCard(
              label: 'Passed',
              value: ((_totalScreened - _totalReferred) * t).round(),
              icon: Icons.check_circle_rounded,
              color: VsColors.emerald,
              bg: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 8),
            _statCard(
              label: 'Referred',
              value: (_totalReferred * t).round(),
              icon: Icons.warning_rounded,
              color: VsColors.rose,
              bg: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 8),
            _statCard(
              label: 'Unsynced',
              value: (_unsyncedCount * t).round(),
              icon: Icons.cloud_upload_rounded,
              color: VsColors.amber,
              bg: Colors.white.withValues(alpha: 0.15),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text('$value',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.0)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9, color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── BANNERS ───────────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VsColors.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VsColors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: VsColors.amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.wifi_off_rounded, size: 16, color: VsColors.amber),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('You are offline',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E))),
            Text('Data saved locally. Sync resumes when connected.',
                style: GoogleFonts.inter(
                    fontSize: 10, color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w400)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: VsColors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('SQLite',
              style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E))),
        ),
      ]),
    );
  }

  Widget _buildSyncBanner() {
    return GestureDetector(
      onTap: _doSync,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: VsColors.skyBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VsColors.sky.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _syncCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _isSyncing ? _syncCtrl.value * 2 * pi : 0,
              child: child,
            ),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: VsColors.sky.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_rounded, size: 16, color: VsColors.sky),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSyncing
                  ? 'Syncing records...'
                  : '$_unsyncedCount record${_unsyncedCount == 1 ? '' : 's'} pending sync',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0369A1))),
          ),
          if (!_isSyncing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: VsColors.sky,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('Sync Now',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            )
          else
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: VsColors.sky),
            ),
        ]),
      ),
    );
  }

  // ── IMPACT BANNER ─────────────────────────────────────────
  Widget _buildImpactBanner() {
    final passed = _totalScreened - _totalReferred;
    final passRate = _totalScreened > 0
        ? (passed / _totalScreened * 100).round()
        : 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(opacity: t,
          child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VsColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VsColors.border),
          boxShadow: VsShadows.card,
        ),
        child: Row(children: [
          // Circular progress
          SizedBox(
            width: 56, height: 56,
            child: Stack(fit: StackFit.expand, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0,
                    end: _totalScreened > 0 ? passed / _totalScreened : 0.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 5,
                  backgroundColor: VsColors.slate200,
                  valueColor: const AlwaysStoppedAnimation(VsColors.emerald),
                ),
              ),
              Center(
                child: Text(
                  _totalScreened == 0 ? '—' : '$passRate%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: VsColors.slate900),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Today\'s Impact',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: VsColors.slate900)),
              const SizedBox(height: 2),
              Text(
                _totalScreened == 0
                    ? 'No screenings yet — start your first test!'
                    : '$passed passed · $_totalReferred referred · $_totalScreened total',
                style: GoogleFonts.inter(
                    fontSize: 12, color: VsColors.slate500,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.location_on_rounded,
                    size: 11, color: VsColors.slate400),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(_locationLabel,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: VsColors.slate400,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ]),
          ),
          // Sight mark mini
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: VsColors.brandFaint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VsColors.brandLight),
            ),
            child: const Center(
              child: VsLogo(size: 26, color: VsColors.brand),
            ),
          ),
        ]),
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────
  Widget _buildSectionHeader(String title, Widget? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: VsColors.slate900)),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── ACTION GRID ───────────────────────────────────────────
  Widget _buildActionGrid() {
    final actions = [
      _ActionData(
        icon: Icons.remove_red_eye_rounded,
        title: 'New Screening',
        subtitle: 'Register & test patient',
        tag: 'START TEST',
        color: VsColors.brand,
        gradientColors: const [Color(0xFF0D9488), Color(0xFF0F766E)],
        illustration: const _EyeScanIllustration(),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) =>
                const NewScreeningScreen(startWithNewPatient: true)))
            .then((_) => _loadDbStats()),
      ),
      _ActionData(
        icon: Icons.groups_rounded,
        title: 'Bulk Mode',
        subtitle: 'Campaign screening',
        tag: 'CAMPAIGN',
        color: VsColors.sky,
        gradientColors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        illustration: const _GroupIllustration(),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BulkModeScreen()))
            .then((_) => _loadDbStats()),
      ),
      _ActionData(
        icon: Icons.school_rounded,
        title: 'Training',
        subtitle: 'Learn the system',
        tag: 'LEARN',
        color: VsColors.amber,
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        illustration: const _BookIllustration(),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TrainingScreen())),
      ),
      _ActionData(
        icon: Icons.bar_chart_rounded,
        title: 'Analytics',
        subtitle: 'Programme data',
        tag: 'INSIGHTS',
        color: VsColors.violet,
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        illustration: const _ChartIllustration(),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: actions.asMap().entries.map((e) {
        final delay = e.key * 90;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 450 + delay),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
          ),
          child: _buildActionCard(e.value),
        );
      }).toList(),
    );
  }

  Widget _buildActionCard(_ActionData a) {
    return _PressableActionCard(data: a);
  }

  // ── TIP CARD ──────────────────────────────────────────────
  Widget _buildTipCard() {
    final tip = _tips[_tipIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
              begin: const Offset(0.05, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_tipIndex),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tip.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tip.color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon, color: tip.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Clinical Tip',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: tip.color, letterSpacing: 0.3)),
              const SizedBox(height: 3),
              Text(tip.text,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: VsColors.slate700,
                      fontWeight: FontWeight.w400, height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          // Dot indicators
          Column(
            children: List.generate(_tips.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 2),
              width: 4,
              height: i == _tipIndex ? 14 : 4,
              decoration: BoxDecoration(
                color: i == _tipIndex
                    ? tip.color
                    : VsColors.slate300,
                borderRadius: BorderRadius.circular(99),
              ),
            )),
          ),
        ]),
      ),
    );
  }

  // ── RECENT SCREENINGS LIST ────────────────────────────────
  Widget _buildRecentList() {
    if (_recentScreenings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.remove_red_eye_outlined,
        title: 'No screenings yet',
        subtitle: 'Tap the eye button below to start your first test.',
      );
    }
    return Column(
      children: _recentScreenings.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 350 + i * 80),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 20 * (1 - t)), child: child),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: i < _recentScreenings.length - 1 ? 10 : 0),
            child: _buildPatientCard(r),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> r) {
    final name     = (r['name'] as String?) ?? 'Unknown';
    final age      = (r['age'] as int?) ?? 0;
    final gender   = (r['gender'] as String?) ?? '';
    final outcome  = (r['outcome'] as String?) ?? 'pending';
    final od       = (r['od_snellen'] as String?) ?? '—';
    final os       = (r['os_snellen'] as String?) ?? '—';
    final pid      = (r['patient_id'] as String?) ?? '';
    final photo    = (r['photo_path'] as String?) ?? '';
    final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join();
    final timeAgo  = _timeAgo((r['screening_date'] as String?) ?? '');

    final Color accent;
    final Color badgeBg;
    final Color badgeText;
    final IconData badgeIcon;
    final String badgeLabel;

    switch (outcome) {
      case 'pass':
        accent = VsColors.emerald; badgeBg = VsColors.emeraldBg;
        badgeText = const Color(0xFF065F46); badgeIcon = Icons.check_circle_rounded;
        badgeLabel = 'Pass';
        break;
      case 'refer':
        accent = VsColors.rose; badgeBg = VsColors.roseBg;
        badgeText = const Color(0xFF9F1239); badgeIcon = Icons.warning_rounded;
        badgeLabel = 'Refer';
        break;
      default:
        accent = VsColors.amber; badgeBg = VsColors.amberBg;
        badgeText = const Color(0xFF92400E); badgeIcon = Icons.schedule_rounded;
        badgeLabel = 'Pending';
    }

    return Container(
      decoration: BoxDecoration(
        color: VsColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VsColors.border),
        boxShadow: VsShadows.card,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Accent bar
            Container(
              width: 3, height: 64,
              decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: photo.isNotEmpty && File(photo).existsSync()
                    ? Image.file(File(photo), fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withValues(alpha: 0.6)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15, fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: VsColors.slate900)),
                const SizedBox(height: 3),
                Text('$gender · $age yrs',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: VsColors.slate500)),
                const SizedBox(height: 6),
                if (outcome != 'pending')
                  Row(children: [
                    _vaPill('OD', od, accent),
                    const SizedBox(width: 4),
                    _vaPill('OS', os, accent),
                  ])
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: VsColors.amberBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Awaiting screening',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: VsColors.amber,
                            fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(badgeIcon, size: 10, color: accent),
                const SizedBox(width: 3),
                Text(badgeLabel,
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: badgeText)),
              ]),
            ),
          ]),
        ),
        // Bottom strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(13),
              bottomRight: Radius.circular(13),
            ),
            border: Border(top: BorderSide(color: accent.withValues(alpha: 0.1))),
          ),
          child: Row(children: [
            Icon(Icons.badge_outlined, size: 11, color: VsColors.slate400),
            const SizedBox(width: 4),
            Expanded(
              child: Text(pid,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: VsColors.slate400,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.access_time_rounded, size: 11, color: VsColors.slate400),
            const SizedBox(width: 4),
            Text(timeAgo,
                style: GoogleFonts.inter(
                    fontSize: 10, color: VsColors.slate400,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }

  Widget _vaPill(String eye, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text('$eye $value',
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
    );
  }

  // ── REFERRAL LIST ─────────────────────────────────────────
  Widget _buildReferralList() {
    if (_referredPatients.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No referrals yet',
        subtitle: 'Referred patients will appear here for follow-up.',
      );
    }
    return Column(
      children: _referredPatients.take(3).toList().asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final name     = (r['name'] as String?) ?? 'Unknown';
        final age      = (r['age'] as int?) ?? 0;
        final gender   = (r['gender'] as String?) ?? '';
        final facility = ((r['referral_facility'] as String?) ?? '').isEmpty
            ? 'No facility set' : r['referral_facility'] as String;
        final status   = (r['referral_status'] as String?) ?? 'pending';
        final photo    = (r['photo_path'] as String?) ?? '';
        final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join();
        final appt     = r['appointment_date'] as String?;
        String dueLabel = 'No date set';
        if (appt != null && appt.isNotEmpty) {
          try {
            final dt = DateTime.parse(appt);
            dueLabel = 'Due ${dt.day}/${dt.month}/${dt.year}';
          } catch (_) {}
        }

        final Color statusColor;
        switch (status) {
          case 'overdue':   statusColor = VsColors.rose;    break;
          case 'completed': statusColor = VsColors.emerald; break;
          case 'notified':  statusColor = VsColors.sky;     break;
          default:          statusColor = VsColors.amber;
        }

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 350 + i * 80),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 16 * (1 - t)), child: child),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VsColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: VsColors.border),
                boxShadow: VsShadows.card,
              ),
              child: Row(children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: statusColor.withValues(alpha: 0.15),
                  ),
                  child: photo.isNotEmpty && File(photo).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(photo), fit: BoxFit.cover))
                      : Center(
                          child: Text(initials,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w800,
                                  color: statusColor)),
                        ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: VsColors.slate900)),
                    const SizedBox(height: 2),
                    Text('$gender · $age yrs',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: VsColors.slate500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.local_hospital_outlined,
                          size: 11, color: VsColors.slate400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(facility,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: VsColors.slate500,
                                fontWeight: FontWeight.w500)),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(width: 8),
                // Status + due
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dueLabel,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: VsColors.slate400,
                          fontWeight: FontWeight.w500)),
                ]),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: VsColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VsColors.border),
      ),
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: VsColors.brandFaint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: VsColors.brand, size: 26),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: VsColors.slate700)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, color: VsColors.slate400, height: 1.5)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────
class _TipData {
  const _TipData(this.icon, this.color, this.text);
  final IconData icon;
  final Color color;
  final String text;
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.gradientColors,
    required this.illustration,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final List<Color> gradientColors;
  final Widget illustration;
  final VoidCallback onTap;
}

// ─────────────────────────────────────────────────────────────
// Pressable Action Card — clinical gradient design
// ─────────────────────────────────────────────────────────────
class _PressableActionCard extends StatefulWidget {
  const _PressableActionCard({required this.data});
  final _ActionData data;

  @override
  State<_PressableActionCard> createState() => _PressableActionCardState();
}

class _PressableActionCardState extends State<_PressableActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;
  late final Animation<double> _pressGlow;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _pressScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
    _pressGlow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.data;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        a.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(
          scale: _pressScale.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: a.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: a.color.withValues(alpha: 0.38),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: a.color.withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Dot pattern overlay ──
                Positioned.fill(
                  child: CustomPaint(painter: _CardDotPainter()),
                ),
                // ── Large illustration — bottom-right watermark ──
                Positioned(
                  right: -12, bottom: -12,
                  child: Opacity(
                    opacity: 0.18,
                    child: SizedBox(
                      width: 90, height: 90,
                      child: a.illustration,
                    ),
                  ),
                ),
                // ── Decorative arc top-right ──
                Positioned(
                  top: -20, right: -20,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.5),
                    ),
                  ),
                ),
                Positioned(
                  top: -5, right: -5,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1),
                    ),
                  ),
                ),
                // ── Content ──
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: icon + tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with glow container
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(a.icon,
                                color: Colors.white, size: 19),
                          ),
                          // Tag pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: Text(a.tag,
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.6)),
                          ),
                        ],
                      ),

                      // Bottom: title + subtitle + arrow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1)),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(a.subtitle,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontWeight: FontWeight.w400)),
                              ),
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            ],
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
      ),
    );
  }
}

// Dot pattern for action cards
class _CardDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, p);
      }
    }
  }
  @override
  bool shouldRepaint(_CardDotPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Dot pattern painter
// ─────────────────────────────────────────────────────────────
class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, p);
      }
    }
  }
  @override
  bool shouldRepaint(_DotPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Action card mini-illustrations (CustomPainter)
// ─────────────────────────────────────────────────────────────
class _EyeScanIllustration extends StatelessWidget {
  const _EyeScanIllustration();
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(80, 80), painter: _EyeScanPainter());
}

class _EyeScanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = VsColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2, cy = size.height / 2;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 60, height: 34), p);
    canvas.drawCircle(Offset(cx, cy), 12, p);
    canvas.drawCircle(Offset(cx, cy), 6,
        Paint()..color = VsColors.brand..style = PaintingStyle.fill);
    // Scan line
    canvas.drawLine(Offset(cx - 30, cy + 20), Offset(cx + 30, cy + 20),
        p..color = VsColors.brand.withValues(alpha: 0.4)..strokeWidth = 1.5);
  }
  @override
  bool shouldRepaint(_EyeScanPainter old) => false;
}

class _GroupIllustration extends StatelessWidget {
  const _GroupIllustration();
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(80, 80), painter: _GroupPainter());
}

class _GroupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = VsColors.sky
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final pf = Paint()..color = VsColors.sky.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    for (final (cx, cy) in [(20.0, 40.0), (40.0, 30.0), (60.0, 40.0)]) {
      canvas.drawCircle(Offset(cx, cy - 12), 8, pf);
      canvas.drawCircle(Offset(cx, cy - 12), 8, p);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + 4), width: 24, height: 16),
          3.14, 3.14, false, p);
    }
  }
  @override
  bool shouldRepaint(_GroupPainter old) => false;
}

class _BookIllustration extends StatelessWidget {
  const _BookIllustration();
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(80, 80), painter: _BookPainter());
}

class _BookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = VsColors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final pf = Paint()..color = VsColors.amber.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final book = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: 44, height: 52),
        const Radius.circular(4));
    canvas.drawRRect(book, pf);
    canvas.drawRRect(book, p);
    canvas.drawLine(Offset(size.width/2, size.height/2 - 26),
        Offset(size.width/2, size.height/2 + 26), p..strokeWidth = 1.5);
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
          Offset(size.width/2 + 4, size.height/2 - 10 + i * 8.0),
          Offset(size.width/2 + 18, size.height/2 - 10 + i * 8.0),
          p..strokeWidth = 1.5);
    }
  }
  @override
  bool shouldRepaint(_BookPainter old) => false;
}

class _ChartIllustration extends StatelessWidget {
  const _ChartIllustration();
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(80, 80), painter: _ChartPainter());
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = VsColors.violet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final pf = Paint()..color = VsColors.violet.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    final bars = [0.4, 0.7, 0.5, 0.9, 0.6];
    for (int i = 0; i < bars.length; i++) {
      final x = 10.0 + i * 14.0;
      final h = bars[i] * 50;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 60 - h, 10, h), const Radius.circular(3));
      canvas.drawRRect(rect, pf);
      canvas.drawRRect(rect, p..strokeWidth = 1.5);
    }
    // Trend line
    final path = Path()..moveTo(15, 60 - 0.4 * 50);
    for (int i = 1; i < bars.length; i++) {
      path.lineTo(15 + i * 14.0, 60 - bars[i] * 50);
    }
    canvas.drawPath(path, p..strokeWidth = 2.0..color = VsColors.violet.withValues(alpha: 0.7));
  }
  @override
  bool shouldRepaint(_ChartPainter old) => false;
}
