import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/screening_repository.dart';
import '../utils/app_theme.dart';
import '../widgets/vs_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _readKey = 'notifications_read_ids';
  static const _dismissedKey = 'notifications_dismissed_ids';

  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final data = await ScreeningRepository.instance.getNotifications();
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readKey)?.toSet() ?? <String>{};
    final dismissedIds =
        prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};
    final visible = data
        .where((n) => !dismissedIds.contains(_notificationId(n)))
        .map((n) => Map<String, dynamic>.from(n))
        .toList();
    for (final n in visible) {
      if (readIds.contains(_notificationId(n))) {
        n['read'] = true;
      }
    }
    if (mounted) {
      setState(() {
        _notifications = visible;
        _loading = false;
      });
    }
  }

  String _notificationId(Map<String, dynamic> notification) =>
      notification['id'] as String;

  bool _isTransientNotification(Map<String, dynamic> notification) =>
      _notificationId(notification).startsWith('sync_pending');

  IconData _iconFor(String key) {
    switch (key) {
      case 'warning':
        return Icons.warning_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'check':
        return Icons.check_circle_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'sync':
        return Icons.sync_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _timeLabel(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}hr ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays}d ago';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _markRead(int index) async {
    final notification = _notifications[index];
    setState(() => notification['read'] = true);
    if (_isTransientNotification(notification)) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_readKey)?.toSet() ?? <String>{};
    ids.add(_notificationId(notification));
    await prefs.setStringList(_readKey, ids.toList());
  }

  Future<void> _dismiss(int index) async {
    final notification = _notifications[index];
    setState(() => _notifications.removeAt(index));
    if (_isTransientNotification(notification)) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};
    ids.add(_notificationId(notification));
    await prefs.setStringList(_dismissedKey, ids.toList());
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final n in _notifications) {
        n['read'] = true;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_readKey)?.toSet() ?? <String>{};
    ids.addAll(
      _notifications
          .where((notification) => !_isTransientNotification(notification))
          .map(_notificationId),
    );
    await prefs.setStringList(_readKey, ids.toList());
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).length;
    final newNotifs = _notifications.where((n) => n['read'] == false).toList();
    final earlierNotifs = _notifications
        .where((n) => n['read'] == true)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context, unread),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                  )
                : _notifications.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: const Color(0xFF0D9488),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      children: [
                        if (newNotifs.isNotEmpty) ...[
                          _buildGroupLabel('New', newNotifs.length),
                          ...newNotifs.map(
                            (n) => _buildNotifCard(_notifications.indexOf(n)),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (earlierNotifs.isNotEmpty) ...[
                          _buildGroupLabel('Earlier', null),
                          ...earlierNotifs.map(
                            (n) => _buildNotifCard(_notifications.indexOf(n)),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unread) {
    return VsGradientHeader(
      eyebrow: 'Alerts',
      title: 'Notifications',
      subtitle: unread > 0
          ? '$unread unread item${unread == 1 ? '' : 's'}'
          : 'You are all caught up',
      icon: Icons.notifications_rounded,
      leading: _HeaderBackButton(onTap: () => Navigator.pop(context)),
      trailing: unread > 0
          ? TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Mark read'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VsRadius.pill),
                ),
              ),
            )
          : null,
      bottom: Row(
        children: [
          Expanded(
            child: _HeaderMetric(
              value: '${_notifications.length}',
              label: 'Total',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HeaderMetric(value: '$unread', label: 'Unread'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupLabel(String label, int? count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '· $count new',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0D9488),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotifCard(int index) {
    final n = _notifications[index];
    final isRead = n['read'] as bool;
    final color = Color(n['color'] as int);
    final icon = _iconFor(n['icon'] as String);
    final timeStr = _timeLabel(n['time'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key('notif_${_notificationId(n)}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFFEF4444)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        onDismissed: (_) => _dismiss(index),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => _markRead(index),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isRead
                      ? const Color(0xFFEEF2F6)
                      : color.withValues(alpha: 0.35),
                  width: isRead ? 1 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isRead
                        ? Colors.black.withValues(alpha: 0.04)
                        : color.withValues(alpha: 0.12),
                    blurRadius: isRead ? 8 : 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isRead
                                ? [
                                    const Color(0xFFEEF2F6),
                                    const Color(0xFFEEF2F6),
                                  ]
                                : [color, color.withValues(alpha: 0.5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withValues(
                                            alpha: isRead ? 0.07 : 0.2,
                                          ),
                                          color.withValues(
                                            alpha: isRead ? 0.03 : 0.08,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: color.withValues(
                                          alpha: isRead ? 0.1 : 0.35,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: color.withValues(
                                        alpha: isRead ? 0.45 : 1.0,
                                      ),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n['title'] as String,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  color: isRead
                                                      ? const Color(0xFF5E7291)
                                                      : const Color(0xFF1A2A3D),
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 9,
                                                height: 9,
                                                margin: const EdgeInsets.only(
                                                  left: 6,
                                                  top: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: color.withValues(
                                                        alpha: 0.55,
                                                      ),
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          n['body'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF8FA0B4),
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? const Color(0xFFF8FAFB)
                                    : color.withValues(alpha: 0.05),
                                border: Border(
                                  top: BorderSide(
                                    color: isRead
                                        ? const Color(0xFFEEF2F6)
                                        : color.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 10,
                                          color: Color(0xFFB0BEC5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: const Color(0xFFB0BEC5),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(
                                        alpha: isRead ? 0.06 : 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: color.withValues(
                                          alpha: isRead ? 0.1 : 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      n['tag'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: color.withValues(
                                          alpha: isRead ? 0.55 : 1.0,
                                        ),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isRead)
                                    InkWell(
                                      onTap: () => _markRead(index),
                                      borderRadius: BorderRadius.circular(99),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                          border: Border.all(
                                            color: color.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          'Mark read',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 12,
                                          color: const Color(
                                            0xFF22C55E,
                                          ).withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Read',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFB0BEC5),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D9488).withValues(alpha: 0.06),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF134E4A), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_off_rounded,
                  color: Color(0xFF5EEAD4),
                  size: 36,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF8FAFB),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A2A3D),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications right now.\nCheck back after your next screening.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF8FA0B4),
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(VsRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Text(value, style: VsText.headline(color: Colors.white)),
          const SizedBox(width: 6),
          Text(
            label,
            style: VsText.label(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}
