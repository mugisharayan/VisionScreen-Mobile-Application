import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bulk_mode_screen.dart';
import 'new_screening_screen.dart';
import 'notifications_screen.dart';
import 'training_screen.dart';
import '../features/home/home_controller.dart';
import '../utils/app_theme.dart';
import '../utils/haptics.dart';
import '../utils/page_transitions.dart';
import '../widgets/main_shell_scope.dart';
import '../widgets/vs_logo.dart';
import '../widgets/vs_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final HomeController _controller;

  // -- Animations --------------------------------------------
  // Header entry (slide + fade)
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;

  // Stats counter (number roll-up)
  late final AnimationController _statsCtrl;
  late final Animation<double> _statsAnim;

  // Sync spin
  late final AnimationController _syncCtrl;

  // -- Lifecycle ---------------------------------------------
  @override
  void initState() {
    super.initState();
    _controller = HomeController()..addListener(_handleControllerChanged);

    // Header entry
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    // Stats roll-up
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _statsAnim = CurvedAnimation(
      parent: _statsCtrl,
      curve: Curves.easeOutCubic,
    );

    // Sync spin
    _syncCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    unawaited(
      _controller.initialize().then((_) {
        if (mounted) {
          _startEntranceAnimations();
        }
      }),
    );
  }

  Future<void> _onRefresh() async {
    _statsCtrl.forward(from: 0);
    await _controller.refresh();
  }

  Future<void> _doSync() async {
    if (_isSyncing) return;
    if (!_syncConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cloud workspace is not configured. Records remain on this device.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: VsColors.sky,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    VsHaptics.medium();
    final result = await _controller.syncNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Sync finished: ${result.appliedChanges} uploaded, ${result.restoredRecords} refreshed.'
              : result.errorMessage ?? 'Sync failed.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: result.success ? VsColors.emerald : VsColors.rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchLocation() async {
    await _controller.refreshLocation(context);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _headerCtrl.dispose();
    _statsCtrl.dispose();
    _syncCtrl.dispose();
    super.dispose();
  }

  // -- Helpers -----------------------------------------------
  String get _chwPhoto => _controller.chwPhoto;
  int get _totalScreened => _controller.totalScreened;
  int get _totalReferred => _controller.totalReferred;
  int get _unsyncedCount => _controller.unsyncedCount;
  int get _notificationCount => _controller.notificationCount;
  bool get _isSyncing => _controller.isSyncing;
  bool get _syncConfigured => _controller.syncConfigured;
  String get _lastSyncError => _controller.lastSyncError;
  bool get _isOffline => _controller.isOffline;
  String get _locationLabel => _controller.locationLabel;
  DateTime get _now => _controller.now;
  String get _greeting => _controller.greeting;
  String get _firstName => _controller.firstName;
  String get _initials => _controller.initials;
  String _fmtDate(DateTime dateTime) => _controller.formatDate(dateTime);

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startEntranceAnimations() {
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _statsCtrl.forward();
      }
    });
  }

  // -- Build -------------------------------------------------
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
            // Sync banner — only when there are unsynced records pending
            if (_syncConfigured && _unsyncedCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildSyncBanner(),
                ),
              ),
            // Body content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTodaySummary(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Quick Actions', null),
                  _buildActionGrid(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- HEADER ------------------------------------------------
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerOpacity,
      child: SlideTransition(
        position: _headerSlide,
        child: VsGradientHeader(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          topRow: Row(
            children: [
              Expanded(child: _buildBrandWordmark()),
              _buildNotifBell(),
              const SizedBox(width: 8),
              _buildAvatar(),
            ],
          ),
          title: _firstName.isEmpty ? 'Welcome' : '$_firstName 👋',
          subtitle: '$_greeting · ${_fmtDate(_now)}',
          bottom: _buildHeaderLocationButton(),
        ),
      ),
    );
  }

  Widget _buildBrandWordmark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VsLogo(size: 24, showRing: false),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Vision',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Screen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderLocationButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(VsRadius.pill),
      child: InkWell(
        onTap: _fetchLocation,
        borderRadius: BorderRadius.circular(VsRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locationLabel,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- TODAY SUMMARY (stats card under the hero) ------------
  Widget _buildTodaySummary() {
    final passed = _totalScreened - _totalReferred;
    final items = [
      ('Screened', _totalScreened, VsColors.sky),
      ('Passed', passed, VsColors.emerald),
      ('Referred', _totalReferred, VsColors.rose),
      ('Unsynced', _unsyncedCount, VsColors.amber),
    ];
    return AnimatedBuilder(
      animation: _statsAnim,
      builder: (_, _) {
        final t = _statsAnim.value;
        Widget tile(int index) => _CompactSummaryTile(
          value: '${(items[index].$2 * t).round()}',
          label: items[index].$1,
          color: items[index].$3,
        );

        return VsCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: List.generate(items.length * 2 - 1, (index) {
              if (index.isOdd) {
                return Container(
                  width: 1,
                  height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: VsColors.border,
                );
              }
              return Expanded(child: tile(index ~/ 2));
            }),
          ),
        );
      },
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, primaryAnimation, secondaryAnimation) =>
            const NotificationsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
    _controller.clearNotifications();
  }

  Widget _buildNotifBell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        VsIconButton(
          icon: _notificationCount > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_rounded,
          tooltip: 'Open notifications',
          onTap: _openNotifications,
          foreground: Colors.white,
          tint: Colors.white.withValues(alpha: 0.15),
          size: 38,
          iconSize: 18,
        ),
        if (_notificationCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: VsColors.rose,
                shape: BoxShape.circle,
                border: Border.all(color: VsColors.brandDeep, width: 1.5),
              ),
              child: Text(
                '$_notificationCount',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [VsColors.brandLight, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _chwPhoto.isNotEmpty && File(_chwPhoto).existsSync()
            ? Image.file(
                File(_chwPhoto),
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              )
            : Center(
                child: Text(
                  _initials,
                  style: GoogleFonts.plusJakartaSans(
                    color: VsColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
      ),
    );
  }

  // -- BANNERS -----------------------------------------------
  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VsColors.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VsColors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: VsColors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 16,
              color: VsColors.amber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                Text(
                  'Data saved locally. Sync resumes when connected.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: VsColors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'SQLite',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBanner() {
    final canSync = _syncConfigured && !_isSyncing;
    final statusText = _isSyncing
        ? 'Syncing records...'
        : !_syncConfigured
        ? 'Cloud workspace is not configured. Records stay on this device.'
        : _lastSyncError.isNotEmpty
        ? 'Last sync failed. Tap to retry.'
        : _unsyncedCount == 0
        ? 'All local changes are synced.'
        : '$_unsyncedCount record${_unsyncedCount == 1 ? '' : 's'} waiting to sync';
    final pillColor = _syncConfigured ? VsColors.sky : VsColors.skyBg;
    final pillTextColor = _syncConfigured
        ? Colors.white
        : const Color(0xFF0369A1);
    final pillText = _syncConfigured ? 'Sync Now' : 'Local only';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canSync ? _doSync : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: VsColors.skyBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VsColors.sky.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _syncCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: _isSyncing ? _syncCtrl.value * 2 * pi : 0,
                  child: child,
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: VsColors.sky.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    size: 16,
                    color: VsColors.sky,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ),
              if (!_isSyncing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    pillText,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: pillTextColor,
                    ),
                  ),
                )
              else
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VsColors.sky,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -- SECTION HEADER ----------------------------------------
  Widget _buildSectionHeader(String title, Widget? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: VsColors.slate900,
            ),
          ),
        ),
        ...switch (trailing) {
          final trailingWidget? => [trailingWidget],
          null => const <Widget>[],
        },
      ],
    );
  }

  // -- ACTION GRID -------------------------------------------
  Widget _buildActionGrid() {
    final actions = [
      _ActionData(
        primary: true,
        icon: Icons.remove_red_eye_rounded,
        title: 'New Screening',
        subtitle: 'Register and test patient',
        accent: VsColors.brand,
        illustration: const _EyeScanIllustration(),
        onTap: () => Navigator.push(
          context,
          VsPageRoute(
            builder: (_) => const NewScreeningScreen(startWithNewPatient: true),
          ),
        ).then((_) => _controller.refresh()),
      ),
      _ActionData(
        primary: true,
        icon: Icons.groups_rounded,
        title: 'Bulk Mode',
        subtitle: 'Campaign screening',
        accent: VsColors.brand,
        illustration: const _GroupIllustration(),
        onTap: () => Navigator.push(
          context,
          VsPageRoute(builder: (_) => const BulkModeScreen()),
        ).then((_) => _controller.refresh()),
      ),
      _ActionData(
        primary: false,
        icon: Icons.school_rounded,
        title: 'Training',
        subtitle: 'Learn the system',
        accent: VsColors.amber,
        illustration: const SizedBox.shrink(),
        onTap: () => Navigator.push(
          context,
          VsPageRoute(builder: (_) => const TrainingScreen()),
        ),
      ),
      _ActionData(
        primary: false,
        icon: Icons.list_alt_rounded,
        title: 'Activity',
        subtitle: 'Screenings and follow-ups',
        accent: VsColors.violet,
        illustration: const SizedBox.shrink(),
        onTap: () =>
            MainShellScope.of(context).selectTab(MainShellTab.activity),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = (constraints.maxWidth - 12) / 2;
        const cardH = 140.0;
        final ratio = cardW / cardH;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: actions.map((a) => _PressableActionCard(data: a)).toList(),
        );
      },
    );
  }
}

class _CompactSummaryTile extends StatelessWidget {
  const _CompactSummaryTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: VsText.display(
              color: color,
            ).copyWith(fontSize: 20, height: 1),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: VsText.label(
            color: VsColors.slate700,
            w: FontWeight.w700,
          ).copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.illustration,
    required this.onTap,
  });
  final bool primary;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget illustration;
  final VoidCallback onTap;
}

// -------------------------------------------------------------
// Pressable Action Card.
//
//   primary  → teal gradient surface, white-on-teal (used for
//              "New Screening" and "Bulk Mode" — actions the
//              user is most likely to take on opening the app)
//   secondary → flat white card with subtle border, slate copy
//               (used for "Training" and "Activity" — reference
//               actions). Accent color appears only on the icon
//               tile to keep visual hierarchy with the primary
//               cards.
// -------------------------------------------------------------
class _PressableActionCard extends StatefulWidget {
  const _PressableActionCard({required this.data});
  final _ActionData data;

  @override
  State<_PressableActionCard> createState() => _PressableActionCardState();
}

class _PressableActionCardState extends State<_PressableActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.data;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: (_) {
          VsHaptics.light();
          _pressCtrl.forward();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: () {
          _pressCtrl.reverse();
          a.onTap();
        },
        borderRadius: BorderRadius.circular(VsRadius.lg),
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (_, child) => Transform.scale(
            scale: 1 - (_pressCtrl.value * 0.03),
            child: child,
          ),
          child: a.primary ? _primaryCard(a) : _secondaryCard(a),
        ),
      ),
    );
  }

  Widget _primaryCard(_ActionData a) {
    return Container(
      decoration: BoxDecoration(
        gradient: VsGradients.brand,
        borderRadius: BorderRadius.circular(VsRadius.lg),
        boxShadow: [
          BoxShadow(
            color: VsColors.brand.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Center(child: a.illustration)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: VsText.headline(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.subtitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: VsText.label(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secondaryCard(_ActionData a) {
    return Container(
      decoration: BoxDecoration(
        color: VsColors.card,
        borderRadius: BorderRadius.circular(VsRadius.lg),
        border: Border.all(color: VsColors.border),
        boxShadow: VsShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: a.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(VsRadius.md),
            ),
            child: Icon(a.icon, color: a.accent, size: 20),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: VsText.headline(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.subtitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: VsText.label(),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: a.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(VsRadius.pill),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: a.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Action card mini-illustrations (CustomPainter) — white on gradient
// -------------------------------------------------------------

// ── 1. Eye Scan — detailed eye with scan lines + corner brackets ──
class _EyeScanIllustration extends StatelessWidget {
  const _EyeScanIllustration();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(double.infinity, 44),
    painter: _EyeScanPainter(),
  );
}

class _EyeScanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w * 0.52, cy = h * 0.52;

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final dim = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Eye outline (almond shape via bezier)
    final eyePath = Path();
    eyePath.moveTo(cx - 22, cy);
    eyePath.cubicTo(cx - 14, cy - 14, cx + 14, cy - 14, cx + 22, cy);
    eyePath.cubicTo(cx + 14, cy + 14, cx - 14, cy + 14, cx - 22, cy);
    canvas.drawPath(eyePath, fill);
    canvas.drawPath(eyePath, stroke);

    // Iris circle
    canvas.drawCircle(Offset(cx, cy), 9, fill);
    canvas.drawCircle(Offset(cx, cy), 9, stroke);

    // Pupil filled
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Highlight dot
    canvas.drawCircle(
      Offset(cx + 3, cy - 3),
      1.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Scan line (horizontal dashed)
    for (double x = cx - 22; x < cx + 22; x += 5) {
      canvas.drawLine(Offset(x, cy + 18), Offset(x + 3, cy + 18), dim);
    }

    // Corner brackets (top-left, top-right, bottom-left, bottom-right)
    const bLen = 7.0;
    final bx = cx - 26.0, by = cy - 20.0;
    final bx2 = cx + 26.0, by2 = cy + 20.0;
    // TL
    canvas.drawLine(Offset(bx, by + bLen), Offset(bx, by), dim);
    canvas.drawLine(Offset(bx, by), Offset(bx + bLen, by), dim);
    // TR
    canvas.drawLine(Offset(bx2 - bLen, by), Offset(bx2, by), dim);
    canvas.drawLine(Offset(bx2, by), Offset(bx2, by + bLen), dim);
    // BL
    canvas.drawLine(Offset(bx, by2 - bLen), Offset(bx, by2), dim);
    canvas.drawLine(Offset(bx, by2), Offset(bx + bLen, by2), dim);
    // BR
    canvas.drawLine(Offset(bx2 - bLen, by2), Offset(bx2, by2), dim);
    canvas.drawLine(Offset(bx2, by2), Offset(bx2, by2 - bLen), dim);
  }

  @override
  bool shouldRepaint(_EyeScanPainter old) => false;
}

// ── 2. Group / Campaign — 3 people silhouettes + clipboard ──
class _GroupIllustration extends StatelessWidget {
  const _GroupIllustration();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(double.infinity, 44),
    painter: _GroupPainter(),
  );
}

class _GroupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final fillDim = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw 3 person silhouettes at different x positions
    void drawPerson(double cx, double baseY, double scale, Paint headFill) {
      // Head
      canvas.drawCircle(Offset(cx, baseY - 14 * scale), 5.5 * scale, headFill);
      // Body arc
      final bodyPath = Path();
      bodyPath.moveTo(cx - 9 * scale, baseY + 2 * scale);
      bodyPath.quadraticBezierTo(
        cx,
        baseY - 4 * scale,
        cx + 9 * scale,
        baseY + 2 * scale,
      );
      canvas.drawPath(bodyPath, stroke..strokeWidth = 1.5 * scale);
      // Shoulders fill
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, baseY),
          width: 16 * scale,
          height: 7 * scale,
        ),
        headFill,
      );
    }

    final midY = h * 0.72;
    // Left person (dimmer, behind)
    drawPerson(w * 0.28, midY, 0.82, fillDim);
    // Right person (dimmer, behind)
    drawPerson(w * 0.72, midY, 0.82, fillDim);
    // Center person (main, bright)
    drawPerson(w * 0.50, midY - 2, 1.0, fill);

    // Clipboard on the right
    final clipX = w * 0.84, clipY = h * 0.28;
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(clipX, clipY), width: 18, height: 22),
      const Radius.circular(3),
    );
    canvas.drawRRect(clipRect, fillDim);
    canvas.drawRRect(clipRect, stroke..strokeWidth = 1.2);
    // Clip top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(clipX, clipY - 11), width: 8, height: 4),
        const Radius.circular(2),
      ),
      fill,
    );
    // Lines on clipboard
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(clipX - 5, clipY - 4 + i * 5.0),
        Offset(clipX + 5, clipY - 4 + i * 5.0),
        stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.6),
      );
    }

    // Check mark badge
    canvas.drawCircle(
      Offset(w * 0.16, h * 0.28),
      8,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    final check = Path();
    check.moveTo(w * 0.16 - 4, h * 0.28);
    check.lineTo(w * 0.16 - 1, h * 0.28 + 3);
    check.lineTo(w * 0.16 + 4, h * 0.28 - 3);
    canvas.drawPath(
      check,
      stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_GroupPainter old) => false;
}
