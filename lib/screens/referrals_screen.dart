import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'patients_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFF04091A);
const _ink2 = Color(0xFF0B1530);
const _teal = Color(0xFF0D9488);
const _teal2 = Color(0xFF14B8A6);
const _teal3 = Color(0xFF5EEAD4);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _blue = Color(0xFF3B82F6);

class _Referral {
  const _Referral({
    required this.initials,
    required this.avatarColors,
    required this.photoUrl,
    required this.name,
    required this.demographic,
    required this.facility,
    required this.dueDate,
    required this.status,
    required this.od,
    required this.os,
  });
  final String initials;
  final List<Color> avatarColors;
  final String photoUrl;
  final String name;
  final String demographic;
  final String facility;
  final String dueDate;
  final String
  status; // overdue | notified | pending | attended | completed | cancelled
  final String od, os;
}

final _referrals = <_Referral>[
  _Referral(
    initials: 'OJ',
    avatarColors: [Color(0xFF7F1D1D), _red],
    photoUrl:
        'https://images.unsplash.com/photo-1506277886164-e25aa3f4ef7f?w=150&q=80',
    name: 'Okello James',
    demographic: 'M · 58 yrs',
    facility: 'Mulago National Referral Hospital',
    dueDate: '29 Mar 2026',
    status: 'overdue',
    od: '6/12',
    os: '6/18',
  ),
  _Referral(
    initials: 'BS',
    avatarColors: [Color(0xFF1E3A5F), _blue],
    photoUrl:
        'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=150&q=80',
    name: 'Byaruhanga Sam',
    demographic: 'M · 62 yrs',
    facility: 'Kampala Eye Clinic',
    dueDate: '2 Apr 2026',
    status: 'notified',
    od: '6/24',
    os: '6/36',
  ),
  _Referral(
    initials: 'KK',
    avatarColors: [Color(0xFF78350F), _amber],
    photoUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
    name: 'Kabanda Kevin',
    demographic: 'M · 41 yrs',
    facility: 'Nsambya Hospital',
    dueDate: '5 Apr 2026',
    status: 'pending',
    od: '6/18',
    os: '6/12',
  ),
  _Referral(
    initials: 'AN',
    avatarColors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    photoUrl:
        'https://images.unsplash.com/photo-1516627145497-ae6968895b74?w=150&q=80',
    name: 'Apio Norah',
    demographic: 'F · 8 yrs',
    facility: 'Mulago National Referral Hospital',
    dueDate: '7 Apr 2026',
    status: 'attended',
    od: '6/18',
    os: '6/12',
  ),
  _Referral(
    initials: 'KR',
    avatarColors: [_teal, _teal2],
    photoUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&q=80',
    name: 'Kyomuhendo Rose',
    demographic: 'F · 19 yrs',
    facility: 'Makerere University Hospital',
    dueDate: '10 Apr 2026',
    status: 'completed',
    od: '6/9',
    os: '6/9',
  ),
  _Referral(
    initials: 'MW',
    avatarColors: [Color(0xFF78350F), _amber],
    photoUrl:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&q=80',
    name: 'Mugisha Wilson',
    demographic: 'M · 45 yrs',
    facility: 'Mengo Hospital',
    dueDate: '12 Apr 2026',
    status: 'cancelled',
    od: '6/12',
    os: '6/18',
  ),
];

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  String _filter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Date';
  bool _sortAscending = false;
  bool _isRefreshing = false;
  bool _showClinicalTip = false;

  static const _filters = [
    'All',
    'Pending',
    'Notified',
    'Attended',
    'Overdue',
    'Completed',
    'Cancelled',
  ];

  static const _sortOptions = [
    'Date',
    'Name',
    'Status',
    'Facility',
    'Priority',
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {
      setState(() {
        _showClinicalTip = true;
      });

      // Mark as not first time
      await prefs.setBool('is_first_time', false);

      // Auto-hide tip after 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _showClinicalTip = false;
          });
        }
      });
    }
  }

  void _dismissClinicalTip() {
    setState(() {
      _showClinicalTip = false;
    });
  }

  List<_Referral> get _filtered {
    var filtered = _referrals.where((r) {
      final matchesFilter =
          _filter == 'All' || r.status == _filter.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.facility.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.demographic.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'Name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'Status':
          comparison = _getStatusPriority(
            a.status,
          ).compareTo(_getStatusPriority(b.status));
          break;
        case 'Facility':
          comparison = a.facility.compareTo(b.facility);
          break;
        case 'Priority':
          comparison = _getUrgencyScore(a).compareTo(_getUrgencyScore(b));
          break;
        case 'Date':
        default:
          comparison = _getDateScore(a).compareTo(_getDateScore(b));
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  int _getStatusPriority(String status) {
    switch (status) {
      case 'overdue':
        return 0;
      case 'pending':
        return 1;
      case 'notified':
        return 2;
      case 'attended':
        return 3;
      case 'completed':
        return 4;
      case 'cancelled':
        return 5;
      default:
        return 6;
    }
  }

  int _getUrgencyScore(_Referral r) {
    // Higher score = more urgent
    int score = 0;
    if (r.status == 'overdue') score += 100;
    if (r.status == 'pending') score += 50;
    if (r.demographic.contains('8 yrs') || r.demographic.contains('9 yrs'))
      score += 30; // Children
    if (r.demographic.contains('58 yrs') || r.demographic.contains('62 yrs'))
      score += 20; // Elderly
    return score;
  }

  int _getDateScore(_Referral r) {
    // Simple date scoring based on due date
    if (r.dueDate.contains('29 Mar')) return 1;
    if (r.dueDate.contains('2 Apr')) return 2;
    if (r.dueDate.contains('5 Apr')) return 3;
    if (r.dueDate.contains('7 Apr')) return 4;
    if (r.dueDate.contains('10 Apr')) return 5;
    if (r.dueDate.contains('12 Apr')) return 6;
    return 7;
  }



  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);

    try {
      // Simulate network call to refresh referrals data
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random failure (20% chance)
      if (DateTime.now().millisecond % 5 == 0) {
        throw Exception('Network timeout');
      }

      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Referrals refreshed successfully',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _showErrorSnackBar(
          'Failed to refresh referrals',
          'Check your connection and try again',
          retryAction: _onRefresh,
        );
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4EC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort Referrals',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2A3D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how to organize your referrals',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8FA0B4),
              ),
            ),
            const SizedBox(height: 20),
            // Sort options
            ..._sortOptions
                .map(
                  (option) => _sortOption(
                    option,
                    _getSortIcon(option),
                    _getSortDescription(option),
                  ),
                )
                .toList(),
            const SizedBox(height: 16),
            // Sort direction toggle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _teal.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: _teal,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort Direction',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2A3D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _sortAscending
                              ? 'Ascending (A-Z, 1-9)'
                              : 'Descending (Z-A, 9-1)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF8FA0B4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sortAscending,
                    onChanged: (value) {
                      setState(() => _sortAscending = value);
                      Navigator.pop(context);
                    },
                    activeColor: _teal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String option, IconData icon, String description) {
    final isSelected = _sortBy == option;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _sortBy = option);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? _teal.withOpacity(0.08) : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? _teal.withOpacity(0.25)
                  : const Color(0xFFEEF2F6),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _teal.withOpacity(0.15)
                      : const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? _teal : const Color(0xFF8FA0B4),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? _teal : const Color(0xFF1A2A3D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8FA0B4),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: _teal, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSortIcon(String option) {
    switch (option) {
      case 'Date':
        return Icons.calendar_today_rounded;
      case 'Name':
        return Icons.sort_by_alpha_rounded;
      case 'Status':
        return Icons.flag_rounded;
      case 'Facility':
        return Icons.local_hospital_rounded;
      case 'Priority':
        return Icons.priority_high_rounded;
      default:
        return Icons.sort_rounded;
    }
  }

  String _getSortDescription(String option) {
    switch (option) {
      case 'Date':
        return 'Sort by due date';
      case 'Name':
        return 'Sort alphabetically by patient name';
      case 'Status':
        return 'Group by referral status';
      case 'Facility':
        return 'Sort by healthcare facility';
      case 'Priority':
        return 'Sort by urgency and risk level';
      default:
        return 'Default sorting';
    }
  }

  void _showErrorSnackBar(
    String title,
    String message, {
    VoidCallback? retryAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: retryAction != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: retryAction,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? _red.withOpacity(0.1)
                        : _teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDestructive
                        ? Icons.warning_rounded
                        : Icons.help_outline_rounded,
                    color: isDestructive ? _red : _teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A3D),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF5E7291),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8FA0B4),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? _red : _teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  confirmText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final overdue = _referrals.where((r) => r.status == 'overdue').length;
    final active = _referrals
        .where((r) => ['pending', 'notified', 'attended'].contains(r.status))
        .length;
    final completed = _referrals.where((r) => r.status == 'completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(overdue, active, completed),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: _teal,
                  child: list.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildCard(list[i]),
                          ),
                        ),
                ),
              ),
            ],
          ),
          // Clinical tip overlay
          if (_showClinicalTip) _buildClinicalTip(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildClinicalTip() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_teal.withOpacity(0.95), _teal2.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Clinical Tip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismissClinicalTip,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to VisionScreen! 👋',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Swipe left on any referral card to quickly call the facility, or swipe right to update the patient status. Tap the export button on each card to share individual patient data.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.swipe_left_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe for quick actions',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Auto-dismiss in 8s',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int overdue, int active, int completed) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_ink, _ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referrals',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_referrals.length} total · $overdue overdue',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _teal3.withOpacity(0.55),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // New referral button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_teal, _teal2]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _teal.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'New Referral',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statChip('${_referrals.length}', 'Total', Colors.white),
                  const SizedBox(width: 8),
                  _statChip('$active', 'Active', _amber),
                  const SizedBox(width: 8),
                  _statChip('$overdue', 'Overdue', _red),
                  const SizedBox(width: 8),
                  _statChip('$completed', 'Completed', _green),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, facility, or demographics...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: _teal3.withOpacity(0.4),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: _teal3.withOpacity(0.5),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: _teal3.withOpacity(0.5),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sort and Filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Sort button
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: _teal3,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Sort',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _teal3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter chips container
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (context, index) =>
                            _filterChip(_filters[index]),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String number, String label, Color numColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: numColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: _teal3.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final active = _filter == label;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? _teal.withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: active ? _teal3 : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? _teal3 : Colors.white.withOpacity(0.55),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(_Referral r) {
    final (statusLabel, statusBg, statusText, statusIcon, accentColor) =
        _statusProps(r.status);
    final referralId = '${r.name}_${r.facility}';

    return Dismissible(
      key: Key(referralId),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Right to left swipe - Call facility
          _callFacility(r);
          return false; // Don't dismiss the card
        } else if (direction == DismissDirection.startToEnd) {
          // Left to right swipe - Quick status update
          _quickStatusUpdate(r);
          return false; // Don't dismiss the card
        }
        return false;
      },
      background: _buildSwipeBackground(isLeftSwipe: true),
      secondaryBackground: _buildSwipeBackground(isLeftSwipe: false),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showUpdateSheet(r),
          borderRadius: BorderRadius.circular(16),
          highlightColor: const Color(0xFFF0F4F7),
          splashColor: const Color(0xFFDDE4EC),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top body
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Accent bar
                      Container(
                        width: 4,
                        height: 68,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: r.avatarColors.last.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            r.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: r.avatarColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  r.initials,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2A3D),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              r.demographic,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8FA0B4),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_hospital_rounded,
                                  size: 11,
                                  color: Color(0xFF8FA0B4),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    r.facility,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF5E7291),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // VA pills
                            Row(
                              children: [
                                _vaPill('OD', r.od),
                                const SizedBox(width: 5),
                                _vaPill('OS', r.os),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        constraints: const BoxConstraints(maxWidth: 90),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: accentColor.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 9, color: accentColor),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: statusText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom bar
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    border: Border(
                      top: BorderSide(color: accentColor.withOpacity(0.12)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.dueDate,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusText,
                        ),
                      ),
                      const Spacer(),
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Export button
                          GestureDetector(
                            onTap: () => _exportPatientData(r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFEEF2F6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.file_download_outlined,
                                    size: 10,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Export',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // WhatsApp share button
                          GestureDetector(
                            onTap: () => _shareToWhatsApp(r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFF25D366,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    size: 10,
                                    color: const Color(0xFF25D366),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'WhatsApp',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF25D366),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Update status indicator
                          Text(
                            'Tap to Update',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: accentColor.withOpacity(0.7),
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
        ),
      ),
    );
  }

  Widget _vaPill(String eye, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _teal.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$eye ',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFF8FA0B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({required bool isLeftSwipe}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isLeftSwipe ? _green.withOpacity(0.1) : _blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLeftSwipe ? _green.withOpacity(0.3) : _blue.withOpacity(0.3),
        ),
      ),
      child: Align(
        alignment: isLeftSwipe ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLeftSwipe ? _green : _blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isLeftSwipe ? _green : _blue).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isLeftSwipe
                      ? Icons.check_circle_rounded
                      : Icons.phone_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isLeftSwipe ? 'Complete' : 'Call',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isLeftSwipe ? _green : _blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _callFacility(_Referral r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Calling ${r.facility}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Regarding ${r.name}\'s referral',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _exportPatientData(_Referral r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4EC),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Export Patient Data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2A3D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${r.name} · ${r.facility}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8FA0B4),
              ),
            ),
            const SizedBox(height: 20),
            // Export options
            _exportPatientOption(
              Icons.picture_as_pdf_outlined,
              'Export as PDF',
              'Complete referral report',
              () => _exportPatientToPDF(r),
            ),
            const SizedBox(height: 12),
            _exportPatientOption(
              Icons.table_chart_outlined,
              'Export as CSV',
              'Data for spreadsheet analysis',
              () => _exportPatientToCSV(r),
            ),
            const SizedBox(height: 12),
            _exportPatientOption(
              Icons.email_outlined,
              'Email Report',
              'Send via email',
              () => _emailPatientReport(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportPatientOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEF2F6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _teal, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2A3D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8FA0B4),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF8FA0B4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportPatientToPDF(_Referral r) async {
    Navigator.pop(context);

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generating PDF for ${r.name}...',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Simulate PDF generation
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random failure (20% chance)
      if (DateTime.now().millisecond % 5 == 0) {
        throw Exception('PDF generation failed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'PDF exported successfully! Saved to Downloads.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        'Export failed',
        'Unable to generate PDF for ${r.name}. Please try again.',
        retryAction: () => _exportPatientToPDF(r),
      );
    }
  }

  void _exportPatientToCSV(_Referral r) async {
    Navigator.pop(context);

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Exporting ${r.name} data to CSV...',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'CSV exported successfully!',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        'Export failed',
        'Unable to export CSV for ${r.name}.',
        retryAction: () => _exportPatientToCSV(r),
      );
    }
  }

  void _emailPatientReport(_Referral r) {
    Navigator.pop(context);

    // In a real app, this would open the email client
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.email_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Opening email client for ${r.name}...',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareToWhatsApp(_Referral r) {
    final message =
        '''
🏥 *VisionScreen Referral Update*

👤 *Patient:* ${r.name}
📊 *Demographics:* ${r.demographic}
🏥 *Facility:* ${r.facility}
📅 *Due Date:* ${r.dueDate}
🔄 *Status:* ${r.status.toUpperCase()}

👁️ *Visual Acuity:*
• OD (Right Eye): ${r.od}
• OS (Left Eye): ${r.os}

📱 *Generated by VisionScreen Mobile App*
⏰ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}
''';

    // In a real app, this would use url_launcher to open WhatsApp
    // For now, we'll show a preview and copy to clipboard
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Share to WhatsApp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A3D),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Preview:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8FA0B4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEF2F6)),
              ),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF1A2A3D),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8FA0B4),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app: launch('https://wa.me/?text=${Uri.encodeComponent(message)}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Message copied! Opening WhatsApp...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF25D366),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Share on WhatsApp',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _quickStatusUpdate(_Referral r) async {
    String newStatus = '';

    switch (r.status) {
      case 'pending':
        newStatus = 'notified';
        break;
      case 'notified':
        newStatus = 'attended';
        break;
      case 'attended':
        newStatus = 'completed';
        break;
      case 'overdue':
        newStatus = 'notified';
        break;
      default:
        newStatus = 'completed';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '${r.name} marked as $newStatus',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.assignment_outlined,
            size: 48,
            color: const Color(0xFFDDE4EC),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching referrals'
                : 'No referrals found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term or clear the filter.'
                : 'Try a different filter.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8FA0B4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.home_rounded,
        'activeIcon': Icons.home_rounded,
        'label': 'Home',
      },
      {
        'icon': Icons.people_alt_rounded,
        'activeIcon': Icons.people_alt_rounded,
        'label': 'Patients',
      },
      {
        'icon': Icons.assignment_rounded,
        'activeIcon': Icons.assignment_rounded,
        'label': 'Referrals',
      },
      {
        'icon': Icons.bar_chart_rounded,
        'activeIcon': Icons.bar_chart_rounded,
        'label': 'Analytics',
      },
      {
        'icon': Icons.settings_rounded,
        'activeIcon': Icons.settings_rounded,
        'label': 'Settings',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEF2F6), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = e.key == 2; // Referrals tab is active
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (e.key == 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                  return;
                }
                if (e.key == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientsScreen()),
                  );
                  return;
                }
                if (e.key == 3) {
                  Navigator.pushReplacementNamed(context, '/home');
                  return;
                }
                if (e.key == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  return;
                }
                // Current tab (referrals) - do nothing
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0D9488).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: isActive ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        e.value['icon'] as IconData,
                        size: isActive ? 26 : 22,
                        color: isActive
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF8FA0B4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: GoogleFonts.inter(
                        fontSize: isActive ? 10 : 9,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF8FA0B4),
                        letterSpacing: isActive ? 0.3 : 0,
                      ),
                      child: Text(e.value['label'] as String),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isActive ? 18 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showUpdateSheet(_Referral r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateStatusSheet(referral: r),
    );
  }

  (String, Color, Color, IconData, Color) _statusProps(String status) {
    return switch (status) {
      'overdue' => (
        'Overdue',
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.error_rounded,
        _amber,
      ),
      'notified' => (
        'Notified',
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
        Icons.notifications_active_rounded,
        _blue,
      ),
      'attended' => (
        'Attended',
        const Color(0xFFEDE9FE),
        const Color(0xFF6D28D9),
        Icons.how_to_reg_rounded,
        const Color(0xFF8B5CF6),
      ),
      'completed' => (
        'Completed',
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        Icons.check_circle_rounded,
        _green,
      ),
      'cancelled' => (
        'Cancelled',
        const Color(0xFFF0F4F7),
        const Color(0xFF5E7291),
        Icons.cancel_rounded,
        const Color(0xFF8FA0B4),
      ),
      _ => (
        'Pending',
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.schedule_rounded,
        _amber,
      ),
    };
  }
}

// ── Update Status Bottom Sheet ──
class _UpdateStatusSheet extends StatefulWidget {
  const _UpdateStatusSheet({required this.referral});
  final _Referral referral;

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  String _selected = '';
  bool _isUpdating = false;

  static const _statuses = [
    ('pending', 'Pending', _amber, Icons.schedule_rounded),
    ('notified', 'Notified', _blue, Icons.notifications_active_rounded),
    ('attended', 'Attended', Color(0xFF8B5CF6), Icons.how_to_reg_rounded),
    ('completed', 'Completed', _green, Icons.check_circle_rounded),
    ('overdue', 'Overdue', _red, Icons.error_rounded),
    ('cancelled', 'Cancelled', Color(0xFF8FA0B4), Icons.cancel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.referral.status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE4EC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update Referral Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A2A3D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.referral.name} · ${widget.referral.facility}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8FA0B4),
            ),
          ),
          const SizedBox(height: 16),
          // Status grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: _statuses.map((s) {
              final (key, label, color, icon) = s;
              final isActive = _selected == key;
              return GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () => setState(() => _selected = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.15)
                        : const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? color : const Color(0xFFEEF2F6),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 12,
                        color: isActive ? color : const Color(0xFF8FA0B4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? color : const Color(0xFF8FA0B4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _updateStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isUpdating ? _teal.withOpacity(0.6) : _teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isUpdating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Updating Status...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Save Status',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus() async {
    setState(() => _isUpdating = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random failure (30% chance)
      if (DateTime.now().millisecond % 3 == 0) {
        throw Exception('Update failed');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status updated to $_selected successfully',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Failed to update status',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Please check your connection and try again',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _updateStatus,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? _red.withOpacity(0.1)
                        : _teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDestructive
                        ? Icons.warning_rounded
                        : Icons.help_outline_rounded,
                    color: isDestructive ? _red : _teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A3D),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF5E7291),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8FA0B4),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? _red : _teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  confirmText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
