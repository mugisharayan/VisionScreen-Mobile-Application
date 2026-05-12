import 'dart:io';

import 'package:flutter/material.dart';

import '../repositories/screening_repository.dart';
import '../utils/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/vs_ui.dart';
import 'patients_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const _filters = ['Today', 'Recent', 'Follow-Ups'];

  final ScreeningRepository _repository = ScreeningRepository.instance;

  String _selectedFilter = _filters.first;
  bool _isLoading = true;
  String _loadError = '';
  List<Map<String, dynamic>> _recentScreenings = const [];
  List<Map<String, dynamic>> _followUps = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = '';
    });

    try {
      final results = await Future.wait([
        _repository.getRecentScreeningsWithPatient(limit: 24),
        _repository.getReferredPatients(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _recentScreenings = results[0];
        _followUps = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = 'Unable to load activity right now.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _todayScreenings {
    final now = DateTime.now();
    return _recentScreenings
        .where((screening) {
          final parsed = _parseDate(screening['screening_date'] as String?);
          return parsed != null &&
              parsed.year == now.year &&
              parsed.month == now.month &&
              parsed.day == now.day;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _visibleScreenings =>
      switch (_selectedFilter) {
        'Today' => _todayScreenings,
        _ => _recentScreenings,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VsColors.scaffold,
      body: RefreshIndicator(
        onRefresh: _load,
        color: VsColors.brand,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: VsGradientHeader(
                eyebrow: 'Operations',
                icon: Icons.list_alt_rounded,
                title: 'Activity',
                subtitle: 'Recent screenings and referral follow-up work',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  VsSegmentedControl(
                    options: _filters,
                    value: _selectedFilter,
                    onChanged: (value) =>
                        setState(() => _selectedFilter = value),
                  ),
                  const SizedBox(height: VsSpace.lg),
                  if (_isLoading)
                    const _ActivityLoadingState()
                  else if (_loadError.isNotEmpty)
                    _buildErrorState()
                  else if (_selectedFilter == 'Follow-Ups') ...[
                    _buildSectionHeader(
                      'Follow-Ups',
                      '${_followUps.length} waiting',
                    ),
                    const SizedBox(height: VsSpace.md),
                    _buildFollowUpsList(_followUps),
                  ] else ...[
                    _buildSectionHeader(
                      _selectedFilter == 'Today'
                          ? 'Today\'s Screenings'
                          : 'Recent Screenings',
                      '${_visibleScreenings.length} loaded',
                    ),
                    const SizedBox(height: VsSpace.md),
                    _buildScreeningsList(_visibleScreenings),
                    const SizedBox(height: VsSpace.xl),
                    _buildSectionHeader(
                      'Follow-Ups',
                      '${_followUps.length} waiting',
                    ),
                    const SizedBox(height: VsSpace.md),
                    _buildFollowUpsPreview(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String meta) {
    return Row(
      children: [
        Expanded(child: Text(title, style: VsText.headline())),
        Text(meta, style: VsText.label()),
      ],
    );
  }

  Widget _buildScreeningsList(List<Map<String, dynamic>> screenings) {
    if (screenings.isEmpty) {
      return _EmptyActivityState(
        icon: Icons.remove_red_eye_outlined,
        title: _selectedFilter == 'Today'
            ? 'No screenings recorded today'
            : 'No screenings recorded yet',
        subtitle: 'Start a screening from Home when you are ready.',
        actionLabel: 'Open patients',
        onTap: _openPatients,
      );
    }

    return Column(
      children: screenings
          .take(_selectedFilter == 'Today' ? 12 : 16)
          .map(_buildScreeningCard)
          .toList(growable: false),
    );
  }

  Widget _buildScreeningCard(Map<String, dynamic> screening) {
    final name = _readString(screening['name'], fallback: 'Unknown patient');
    final patientId = _readString(screening['patient_id']);
    final gender = _readString(screening['gender']);
    final age = screening['age'];
    final photoPath = _readString(screening['photo_path']);
    final outcome = _readString(screening['outcome'], fallback: 'pending');
    final od = _readVisualAcuity(screening['od_snellen']);
    final os = _readVisualAcuity(screening['os_snellen']);
    final initials = _initialsFor(name);
    final timestamp = _formatRelativeDate(
      _parseDate(screening['screening_date'] as String?),
    );
    final badge = _OutcomeBadge.fromOutcome(outcome);

    return Padding(
      padding: const EdgeInsets.only(bottom: VsSpace.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openPatients,
          borderRadius: BorderRadius.circular(VsRadius.lg),
          child: VsCard(
            shadow: true,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AvatarTile(
                      photoPath: photoPath,
                      initials: initials,
                      color: badge.color,
                    ),
                    const SizedBox(width: VsSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VsText.headline(),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _patientMeta(
                              patientId: patientId,
                              gender: gender,
                              age: age,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VsText.label(),
                          ),
                          const SizedBox(height: VsSpace.sm),
                          Wrap(
                            spacing: VsSpace.sm,
                            runSpacing: VsSpace.xs,
                            children: [
                              _InfoChip(label: 'OD $od'),
                              _InfoChip(label: 'OS $os'),
                              _InfoChip(label: timestamp),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: VsSpace.sm),
                    _StatusPill(
                      icon: badge.icon,
                      label: badge.label,
                      color: badge.color,
                      background: badge.background,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpsPreview() {
    if (_followUps.isEmpty) {
      return _EmptyActivityState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No follow-ups waiting',
        subtitle: 'Referred patients will appear here when action is needed.',
        actionLabel: 'Open patients',
        onTap: _openPatients,
      );
    }

    final preview = _followUps.take(3).toList(growable: false);
    return Column(
      children: [
        _buildFollowUpsList(preview),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedFilter = 'Follow-Ups'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('View all follow-ups'),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpsList(List<Map<String, dynamic>> followUps) {
    if (followUps.isEmpty) {
      return _EmptyActivityState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No follow-ups waiting',
        subtitle: 'Referred patients will appear here when action is needed.',
        actionLabel: 'Open patients',
        onTap: _openPatients,
      );
    }

    return Column(
      children: followUps
          .take(16)
          .map(_buildFollowUpCard)
          .toList(growable: false),
    );
  }

  Widget _buildFollowUpCard(Map<String, dynamic> patient) {
    final name = _readString(patient['name'], fallback: 'Unknown patient');
    final gender = _readString(patient['gender']);
    final age = patient['age'];
    final facility = _readString(
      patient['referral_facility'],
      fallback: 'Facility not set',
    );
    final status = _readString(patient['referral_status'], fallback: 'pending');
    final due = _formatAppointment(patient['appointment_date'] as String?);
    final photoPath = _readString(patient['photo_path']);
    final palette = _FollowUpPalette.fromStatus(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: VsSpace.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openPatients,
          borderRadius: BorderRadius.circular(VsRadius.lg),
          child: VsCard(
            shadow: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarTile(
                  photoPath: photoPath,
                  initials: _initialsFor(name),
                  color: palette.color,
                ),
                const SizedBox(width: VsSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VsText.headline(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _patientMeta(gender: gender, age: age),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VsText.label(),
                      ),
                      const SizedBox(height: VsSpace.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.local_hospital_outlined,
                            size: 14,
                            color: VsColors.slate400,
                          ),
                          const SizedBox(width: VsSpace.xs),
                          Expanded(
                            child: Text(
                              facility,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: VsText.body(
                                color: VsColors.slate600,
                                w: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VsSpace.sm),
                      Text(due, style: VsText.label(color: VsColors.slate600)),
                    ],
                  ),
                ),
                const SizedBox(width: VsSpace.sm),
                _StatusPill(
                  icon: palette.icon,
                  label: palette.label,
                  color: palette.color,
                  background: palette.background,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return _EmptyActivityState(
      icon: Icons.sync_problem_rounded,
      title: _loadError,
      subtitle: 'Pull to refresh and try again.',
      actionLabel: 'Retry',
      onTap: _load,
    );
  }

  Future<void> _openPatients() async {
    await Navigator.push(
      context,
      VsPageRoute(builder: (_) => const PatientsScreen()),
    );
    if (mounted) {
      await _load();
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  String _formatRelativeDate(DateTime? value) {
    if (value == null) {
      return 'Recorded';
    }

    final now = DateTime.now();
    final difference = now.difference(value);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24 &&
        now.year == value.year &&
        now.month == value.month &&
        now.day == value.day) {
      return '${difference.inHours}h ago';
    }
    return '${value.day}/${value.month}/${value.year}';
  }

  String _formatAppointment(String? value) {
    final parsed = _parseDate(value);
    if (parsed == null) {
      return 'No appointment date set';
    }
    return 'Due ${parsed.day}/${parsed.month}/${parsed.year}';
  }

  String _patientMeta({
    String patientId = '',
    String gender = '',
    Object? age,
  }) {
    final parts = <String>[];
    if (patientId.isNotEmpty) {
      parts.add(patientId);
    }
    if (gender.isNotEmpty) {
      parts.add(gender);
    }
    if (age is int) {
      parts.add('$age yrs');
    } else if (age is String && age.trim().isNotEmpty) {
      parts.add('${age.trim()} yrs');
    }
    return parts.isEmpty ? 'Patient record' : parts.join(' · ');
  }

  String _readString(Object? value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  String _readVisualAcuity(Object? value) {
    final text = _readString(value);
    return text.isEmpty ? 'Not tested' : text;
  }

  String _initialsFor(String name) {
    final words = name
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (words.isEmpty) {
      return 'VS';
    }
    return words.map((word) => word[0]).join().toUpperCase();
  }
}

class _ActivityLoadingState extends StatelessWidget {
  const _ActivityLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: VsSpace.md),
          child: VsCard(
            child: SizedBox(
              height: 92,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VsCard(
      child: Column(
        children: [
          VsIconTile(icon: icon, color: VsColors.brand, size: 52, iconSize: 24),
          const SizedBox(height: VsSpace.md),
          Text(title, textAlign: TextAlign.center, style: VsText.headline()),
          const SizedBox(height: VsSpace.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: VsText.body(color: VsColors.slate500),
          ),
          const SizedBox(height: VsSpace.lg),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.photoPath,
    required this.initials,
    required this.color,
  });

  final String photoPath;
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VsRadius.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VsRadius.md),
        child: photoPath.isNotEmpty && File(photoPath).existsSync()
            ? Image.file(File(photoPath), fit: BoxFit.cover)
            : Center(
                child: Text(initials, style: VsText.headline(color: color)),
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VsColors.slate100,
        borderRadius: BorderRadius.circular(VsRadius.pill),
      ),
      child: Text(label, style: VsText.label(color: VsColors.slate600)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(VsRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: VsText.label(color: color, w: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OutcomeBadge {
  const _OutcomeBadge({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  factory _OutcomeBadge.fromOutcome(String outcome) {
    return switch (outcome) {
      'pass' => const _OutcomeBadge(
        label: 'Pass',
        color: VsColors.emerald,
        background: VsColors.emeraldBg,
        icon: Icons.check_circle_rounded,
      ),
      'refer' => const _OutcomeBadge(
        label: 'Refer',
        color: VsColors.rose,
        background: VsColors.roseBg,
        icon: Icons.warning_rounded,
      ),
      _ => const _OutcomeBadge(
        label: 'Pending',
        color: VsColors.amber,
        background: VsColors.amberBg,
        icon: Icons.schedule_rounded,
      ),
    };
  }
}

class _FollowUpPalette {
  const _FollowUpPalette({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  factory _FollowUpPalette.fromStatus(String status) {
    return switch (status) {
      'overdue' => const _FollowUpPalette(
        label: 'Overdue',
        color: VsColors.rose,
        background: VsColors.roseBg,
        icon: Icons.warning_rounded,
      ),
      'completed' => const _FollowUpPalette(
        label: 'Completed',
        color: VsColors.emerald,
        background: VsColors.emeraldBg,
        icon: Icons.check_circle_rounded,
      ),
      'notified' => const _FollowUpPalette(
        label: 'Notified',
        color: VsColors.sky,
        background: VsColors.skyBg,
        icon: Icons.notifications_active_rounded,
      ),
      'attended' => const _FollowUpPalette(
        label: 'Attended',
        color: VsColors.sky,
        background: VsColors.skyBg,
        icon: Icons.local_hospital_rounded,
      ),
      'cancelled' => const _FollowUpPalette(
        label: 'Cancelled',
        color: VsColors.slate500,
        background: VsColors.slate100,
        icon: Icons.close_rounded,
      ),
      _ => const _FollowUpPalette(
        label: 'Pending',
        color: VsColors.amber,
        background: VsColors.amberBg,
        icon: Icons.schedule_rounded,
      ),
    };
  }
}
