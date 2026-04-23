import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/database_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final data = await DatabaseHelper.instance.getNotifications();
    if (mounted) setState(() { _notifications = data; _loading = false; });
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'warning': return Icons.warning_rounded;
      case 'reminder': return Icons.notifications_active_rounded;
      case 'check': return Icons.check_circle_rounded;
      case 'assignment': return Icons.assignment_rounded;
      case 'sync': return Icons.sync_rounded;
      default: return Icons.notifications_rounded;
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

  void _markAllRead() => setState(() {
    for (final n in _notifications) n['read'] = true;
  });

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).length;
    final newNotifs = _notifications.where((n) => n['read'] == false).toList();
    final earlierNotifs = _notifications.where((n) => n['read'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F7),
      body: Column(
        children: [
          _buildHeader(context, unread),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
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
                              ...newNotifs.map((n) => _buildNotifCard(_notifications.indexOf(n))),
                              const SizedBox(height: 20),
                            ],
                            if (earlierNotifs.isNotEmpty) ...[
                              _buildGroupLabel('Earlier', null),
                              ...earlierNotifs.map((n) => _buildNotifCard(_notifications.indexOf(n))),
                            ],
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Swipe left on any card to delete',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10,
                                  color: const Color(0xFFB0BEC5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unread) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF04091A), Color(0xFF0B1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Large teal orb top-right
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF0D9488).withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Small accent orb bottom-left
          Positioned(
            bottom: -20, left: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF5EEAD4).withOpacity(0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
                      ),
                    ),
                    const Spacer(),
                    if (unread > 0)
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              const Color(0xFF0D9488).withOpacity(0.3),
                              const Color(0xFF14B8A6).withOpacity(0.15),
                            ]),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.done_all_rounded, size: 13, color: Color(0xFF5EEAD4)),
                            const SizedBox(width: 6),
                            Text('Mark all read', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF5EEAD4))),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Hero title row ────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: unread > 0 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  unread > 0 ? '$unread unread' : 'All caught up ✓',
                                  style: GoogleFonts.ibmPlexSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF5EEAD4)),
                                ),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text('Notifications', style: GoogleFonts.barlow(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0, height: 1.0)),
                          const SizedBox(height: 4),
                          Text(
                            unread > 0 ? 'You have $unread unread · swipe left to dismiss' : 'No new notifications right now',
                            style: GoogleFonts.ibmPlexSans(fontSize: 11, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bell icon with badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 26),
                        ),
                        if (unread > 0)
                          Positioned(
                            top: -6, right: -6,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: const Color(0xFF04091A), width: 2),
                                boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.5), blurRadius: 8)],
                              ),
                              child: Text('$unread', style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Stats row ─────────────────────────────────
                Row(children: [
                  _buildHeaderStat('Total', '${_notifications.length}', const Color(0xFF5EEAD4), Icons.list_alt_rounded),
                  const SizedBox(width: 8),
                  _buildHeaderStat('Unread', '$unread', const Color(0xFFF59E0B), Icons.mark_email_unread_rounded),
                  const SizedBox(width: 8),
                  _buildHeaderStat('Read', '${_notifications.length - unread}', const Color(0xFF22C55E), Icons.mark_email_read_rounded),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.barlow(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1.0)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(), style: GoogleFonts.ibmPlexSans(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.35), letterSpacing: 1.2)),
          ]),
        ),
      ),
    );
  }

  Widget _buildGroupLabel(String label, int? count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: count != null ? const Color(0xFF0D9488) : const Color(0xFF8FA0B4),
            boxShadow: count != null ? [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.5), blurRadius: 6)] : [],
          ),
        ),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: GoogleFonts.ibmPlexSans(fontSize: 10, fontWeight: FontWeight.w900, color: count != null ? const Color(0xFF1A2A3D) : const Color(0xFF8FA0B4), letterSpacing: 2.0)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text('$count new', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                count != null ? const Color(0xFF0D9488).withOpacity(0.3) : const Color(0xFFEEF2F6),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
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
        key: Key('notif_${n['title']}_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFFEF4444)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 4),
            Text('Delete', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
          ]),
        ),
        onDismissed: (_) => setState(() => _notifications.removeAt(index)),
        child: GestureDetector(
          onTap: () => setState(() => _notifications[index]['read'] = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isRead ? const Color(0xFFEEF2F6) : color.withOpacity(0.35), width: isRead ? 1 : 1.8),
              boxShadow: [BoxShadow(color: isRead ? Colors.black.withOpacity(0.04) : color.withOpacity(0.12), blurRadius: isRead ? 8 : 20, offset: const Offset(0, 4))],
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
                          colors: isRead ? [const Color(0xFFEEF2F6), const Color(0xFFEEF2F6)] : [color, color.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [color.withOpacity(isRead ? 0.07 : 0.2), color.withOpacity(isRead ? 0.03 : 0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: color.withOpacity(isRead ? 0.1 : 0.35), width: 1.5),
                                ),
                                child: Icon(icon, color: color.withOpacity(isRead ? 0.45 : 1.0), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(n['title'] as String, style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, color: isRead ? const Color(0xFF5E7291) : const Color(0xFF1A2A3D)))),
                                      if (!isRead)
                                        Container(
                                          width: 9, height: 9,
                                          margin: const EdgeInsets.only(left: 6, top: 2),
                                          decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.55), blurRadius: 8)]),
                                        ),
                                    ]),
                                    const SizedBox(height: 5),
                                    Text(n['body'] as String, style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF8FA0B4), height: 1.6)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isRead ? const Color(0xFFF8FAFB) : color.withOpacity(0.05),
                            border: Border(top: BorderSide(color: isRead ? const Color(0xFFEEF2F6) : color.withOpacity(0.15))),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(99)),
                              child: Row(children: [
                                const Icon(Icons.access_time_rounded, size: 10, color: Color(0xFFB0BEC5)),
                                const SizedBox(width: 4),
                                Text(timeStr, style: GoogleFonts.ibmPlexSans(fontSize: 10, color: const Color(0xFFB0BEC5), fontWeight: FontWeight.w600)),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(isRead ? 0.06 : 0.14),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: color.withOpacity(isRead ? 0.1 : 0.3)),
                              ),
                              child: Text(n['tag'] as String, style: GoogleFonts.ibmPlexSans(fontSize: 8, fontWeight: FontWeight.w900, color: color.withOpacity(isRead ? 0.55 : 1.0), letterSpacing: 1.0)),
                            ),
                            const Spacer(),
                            if (!isRead)
                              GestureDetector(
                                onTap: () => setState(() => _notifications[index]['read'] = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withOpacity(0.3))),
                                  child: Text('Mark read', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                                ),
                              )
                            else
                              Row(children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: const Color(0xFF22C55E).withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Text('Read', style: GoogleFonts.ibmPlexSans(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFB0BEC5))),
                              ]),
                          ]),
                        ),
                      ]),
                    ),
                  ],
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
          Stack(alignment: Alignment.center, children: [
            Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0D9488).withOpacity(0.06))),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF04091A), Color(0xFF0D2137)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.notifications_off_rounded, color: Color(0xFF5EEAD4), size: 36),
            ),
            Positioned(
              bottom: 8, right: 8,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF8FAFB), width: 2.5), boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.4), blurRadius: 8)]),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('All caught up!', style: GoogleFonts.barlow(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1A2A3D), letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text('No new notifications right now.\nCheck back after your next screening.', textAlign: TextAlign.center, style: GoogleFonts.ibmPlexSans(fontSize: 13, color: const Color(0xFF8FA0B4), fontWeight: FontWeight.w500, height: 1.6)),
        ],
      ),
    );
  }
}
