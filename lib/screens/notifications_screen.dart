import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.warning_rounded,
      'color': Color(0xFFEF4444),
      'title': 'Referral Overdue',
      'body': 'Okello James has not attended Mulago Hospital. Immediate follow-up required.',
      'time': '2 min ago',
      'read': false,
      'tag': 'URGENT',
    },
    {
      'icon': Icons.person_add_rounded,
      'color': Color(0xFF0D9488),
      'title': 'New Patient Registered',
      'body': 'Mugisha Wilson has been registered and is awaiting screening.',
      'time': '15 min ago',
      'read': false,
      'tag': 'PATIENT',
    },
    {
      'icon': Icons.sync_rounded,
      'color': Color(0xFF38BDF8),
      'title': 'Sync Pending',
      'body': '3 records are waiting to be synced to MongoDB Atlas.',
      'time': '1 hr ago',
      'read': false,
      'tag': 'SYNC',
    },
    {
      'icon': Icons.check_circle_rounded,
      'color': Color(0xFF22C55E),
      'title': 'Screening Completed',
      'body': 'Akello Mercy passed the Tumbling E test. OD 6/6, OS 6/9.',
      'time': '2 hr ago',
      'read': true,
      'tag': 'RESULT',
    },
    {
      'icon': Icons.notifications_active_rounded,
      'color': Color(0xFF8B5CF6),
      'title': 'Appointment Reminder',
      'body': 'Byaruhanga Sam has an appointment at Kampala Eye Clinic on 2 Apr.',
      'time': '3 hr ago',
      'read': true,
      'tag': 'REMINDER',
    },
    {
      'icon': Icons.assignment_rounded,
      'color': Color(0xFFF59E0B),
      'title': 'Referral Generated',
      'body': 'Referral document created for Okello James — Mulago Hospital.',
      'time': 'Yesterday',
      'read': true,
      'tag': 'REFERRAL',
    },
  ];

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
            child: _notifications.isEmpty
                ? _buildEmpty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    children: [
                      if (newNotifs.isNotEmpty) ...[
                        _buildGroupLabel('New', newNotifs.length),
                        ...newNotifs.map((n) =>
                            _buildNotifCard(_notifications.indexOf(n))),
                        const SizedBox(height: 20),
                      ],
                      if (earlierNotifs.isNotEmpty) ...[
                        _buildGroupLabel('Earlier', null),
                        ...earlierNotifs.map((n) =>
                            _buildNotifCard(_notifications.indexOf(n))),
                      ],
                      const SizedBox(height: 12),
                      // Bottom hint
                      Center(
                        child: Text(
                          'Swipe left on any card to delete',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 10,
                              color: const Color(0xFFB0BEC5),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
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
          colors: [Color(0xFF04091A), Color(0xFF0D2137)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background orb
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0D9488).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const Spacer(),
                    if (unread > 0)
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: const Color(0xFF5EEAD4).withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.done_all_rounded,
                                  size: 13, color: Color(0xFF5EEAD4)),
                              const SizedBox(width: 5),
                              Text('Mark all read',
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF5EEAD4))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              color: Colors.white, size: 24),
                          if (unread > 0)
                            Positioned(
                              top: 7, right: 7,
                              child: Container(
                                width: 9, height: 9,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF0D9488), width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notifications',
                              style: GoogleFonts.barlow(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: unread > 0
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  unread > 0
                                      ? '$unread unread · Swipe left to dismiss'
                                      : 'All caught up ✓',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 11,
                                      color: const Color(0xFF5EEAD4).withOpacity(0.7),
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text('$unread',
                              style: GoogleFonts.barlow(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    _buildHeaderStat('Total', '${_notifications.length}',
                        const Color(0xFF5EEAD4), Icons.list_alt_rounded),
                    const SizedBox(width: 8),
                    _buildHeaderStat('Unread', '$unread',
                        const Color(0xFFF59E0B), Icons.mark_email_unread_rounded),
                    const SizedBox(width: 8),
                    _buildHeaderStat('Read', '${_notifications.length - unread}',
                        const Color(0xFF22C55E), Icons.mark_email_read_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.barlow(
                    fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.45),
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupLabel(String label, int? count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Colored left dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: count != null
                  ? const Color(0xFF0D9488)
                  : const Color(0xFF8FA0B4),
              boxShadow: count != null
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.5),
                        blurRadius: 6,
                      )
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: count != null
                    ? const Color(0xFF1A2A3D)
                    : const Color(0xFF8FA0B4),
                letterSpacing: 2.0),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                '$count new',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    count != null
                        ? const Color(0xFF0D9488).withOpacity(0.3)
                        : const Color(0xFFEEF2F6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(int index) {
    final n = _notifications[index];
    final isRead = n['read'] as bool;
    final color = n['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key('notif_${n['title']}_$index'),
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
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 4),
              Text('Delete',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ],
          ),
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
              border: Border.all(
                color: isRead
                    ? const Color(0xFFEEF2F6)
                    : color.withOpacity(0.35),
                width: isRead ? 1 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isRead
                      ? Colors.black.withOpacity(0.04)
                      : color.withOpacity(0.12),
                  blurRadius: isRead ? 8 : 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left accent bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRead
                              ? [const Color(0xFFEEF2F6), const Color(0xFFEEF2F6)]
                              : [color, color.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Card content
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon box
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(isRead ? 0.07 : 0.2),
                                        color.withOpacity(isRead ? 0.03 : 0.08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: color.withOpacity(
                                            isRead ? 0.1 : 0.35),
                                        width: 1.5),
                                  ),
                                  child: Icon(n['icon'] as IconData,
                                      color: color
                                          .withOpacity(isRead ? 0.45 : 1.0),
                                      size: 22),
                                ),
                                const SizedBox(width: 12),
                                // Text
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
                                              style: GoogleFonts.ibmPlexSans(
                                                  fontSize: 13,
                                                  fontWeight: isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  color: isRead
                                                      ? const Color(0xFF5E7291)
                                                      : const Color(
                                                          0xFF1A2A3D)),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 9,
                                              height: 9,
                                              margin: const EdgeInsets.only(
                                                  left: 6, top: 2),
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: color
                                                        .withOpacity(0.55),
                                                    blurRadius: 8,
                                                  )
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        n['body'] as String,
                                        style: GoogleFonts.ibmPlexSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF8FA0B4),
                                            height: 1.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bottom bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? const Color(0xFFF8FAFB)
                                  : color.withOpacity(0.05),
                              border: Border(
                                top: BorderSide(
                                  color: isRead
                                      ? const Color(0xFFEEF2F6)
                                      : color.withOpacity(0.15),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Time
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time_rounded,
                                          size: 10,
                                          color: const Color(0xFFB0BEC5)),
                                      const SizedBox(width: 4),
                                      Text(n['time'] as String,
                                          style: GoogleFonts.ibmPlexSans(
                                              fontSize: 10,
                                              color: const Color(0xFFB0BEC5),
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Tag chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color
                                        .withOpacity(isRead ? 0.06 : 0.14),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                        color: color.withOpacity(
                                            isRead ? 0.1 : 0.3)),
                                  ),
                                  child: Text(n['tag'] as String,
                                      style: GoogleFonts.ibmPlexSans(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: color.withOpacity(
                                              isRead ? 0.55 : 1.0),
                                          letterSpacing: 1.0)),
                                ),
                                const Spacer(),
                                // Action button
                                if (!isRead)
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _notifications[index]['read'] = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(99),
                                        border: Border.all(
                                            color: color.withOpacity(0.3)),
                                      ),
                                      child: Text('Mark read',
                                          style: GoogleFonts.ibmPlexSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: color)),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          size: 12,
                                          color: const Color(0xFF22C55E)
                                              .withOpacity(0.6)),
                                      const SizedBox(width: 4),
                                      Text('Read',
                                          style: GoogleFonts.ibmPlexSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFB0BEC5))),
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
                    color: const Color(0xFF0D9488).withOpacity(0.06),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF04091A), Color(0xFF0D2137)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(Icons.notifications_off_rounded,
                      color: Color(0xFF5EEAD4), size: 36),
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
                          color: const Color(0xFFF8FAFB), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.4),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('All caught up!',
                style: GoogleFonts.barlow(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A2A3D),
                    letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(
              'No new notifications right now.\nCheck back after your next screening.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: const Color(0xFF8FA0B4),
                  fontWeight: FontWeight.w500,
                  height: 1.6),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Back to Home',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}