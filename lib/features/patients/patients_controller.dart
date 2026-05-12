import 'package:flutter/material.dart';

import '../../repositories/campaign_repository.dart';
import '../../repositories/patient_repository.dart';
import '../../repositories/screening_repository.dart';
import 'patient_list_item.dart';

class PatientsController extends ChangeNotifier {
  PatientsController({
    PatientRepository? patientRepository,
    CampaignRepository? campaignRepository,
    ScreeningRepository? screeningRepository,
  }) : _patientRepository = patientRepository ?? PatientRepository.instance,
       _campaignRepository = campaignRepository ?? CampaignRepository.instance,
       _screeningRepository =
           screeningRepository ?? ScreeningRepository.instance;

  final PatientRepository _patientRepository;
  final CampaignRepository _campaignRepository;
  final ScreeningRepository _screeningRepository;

  String _filter = 'All';
  String _query = '';
  List<PatientListItem> _patients = [];
  List<Map<String, dynamic>> _campaigns = [];
  List<PatientListItem> _allCampaignPatients = [];
  bool _loading = true;

  String get filter => _filter;
  void setFilter(String value) {
    if (_filter == value) {
      return;
    }
    _filter = value;
    notifyListeners();
  }

  String get query => _query;
  void setQuery(String value) {
    final normalised = value.trim().toLowerCase();
    if (_query == normalised) {
      return;
    }
    _query = normalised;
    notifyListeners();
  }

  List<PatientListItem> get patients => List.unmodifiable(_patients);
  List<Map<String, dynamic>> get campaigns => List.unmodifiable(_campaigns);
  List<PatientListItem> get allCampaignPatients =>
      List.unmodifiable(_allCampaignPatients);
  bool get loading => _loading;

  List<Map<String, dynamic>> get filteredCampaigns => _query.isEmpty
      ? _campaigns
      : _campaigns.where((campaign) {
          final q = _query.toLowerCase();
          return (campaign['name'] as String).toLowerCase().contains(q) ||
              (campaign['location'] as String).toLowerCase().contains(q) ||
              (campaign['target_group'] as String).toLowerCase().contains(q);
        }).toList();

  List<PatientListItem> get filteredCampaignPatients => _query.isEmpty
      ? []
      : _allCampaignPatients.where((patient) {
          return patient.name.toLowerCase().contains(_query) ||
              patient.id.toLowerCase().contains(_query) ||
              patient.village.toLowerCase().contains(_query) ||
              (patient.facility?.toLowerCase().contains(_query) ?? false);
        }).toList();

  List<PatientListItem> get filteredPatients => _patients.where((patient) {
    final matchesQuery =
        _query.isEmpty ||
        patient.name.toLowerCase().contains(_query) ||
        patient.id.toLowerCase().contains(_query) ||
        patient.village.toLowerCase().contains(_query) ||
        (patient.facility?.toLowerCase().contains(_query) ?? false);
    final matchesFilter =
        _filter == 'All' ||
        (_filter == 'Pass' && patient.outcome == 'pass') ||
        (_filter == 'Refer' && patient.outcome == 'refer') ||
        (_filter == 'Pending' && patient.outcome == 'pending') ||
        (_filter == 'Child' && patient.ageGroup == 'child') ||
        (_filter == 'Adult' && patient.ageGroup == 'adult') ||
        (_filter == 'Elderly' && patient.ageGroup == 'elderly') ||
        (_filter == 'Overdue' && patient.referralStatus == 'overdue') ||
        (_filter == 'Notified' && patient.referralStatus == 'notified') ||
        (_filter == 'Attended' && patient.referralStatus == 'attended') ||
        (_filter == 'Completed' && patient.referralStatus == 'completed') ||
        (_filter == 'Cancelled' && patient.referralStatus == 'cancelled');
    return matchesQuery && matchesFilter;
  }).toList();

  int get individualTotal => _patients.length;
  int get individualPassed =>
      _patients.where((patient) => patient.outcome == 'pass').length;
  int get individualReferred =>
      _patients.where((patient) => patient.outcome == 'refer').length;
  int get individualPending =>
      _patients.where((patient) => patient.outcome == 'pending').length;

  int get campaignTotal => _campaigns.fold<int>(
    0,
    (sum, campaign) => sum + ((campaign['total'] as int?) ?? 0),
  );
  int get campaignPassed => _campaigns.fold<int>(
    0,
    (sum, campaign) => sum + ((campaign['passed'] as int?) ?? 0),
  );
  int get campaignReferred => _campaigns.fold<int>(
    0,
    (sum, campaign) => sum + ((campaign['referred'] as int?) ?? 0),
  );
  int get campaignPending =>
      _allCampaignPatients.where((patient) => patient.outcome == 'pending').length;

  int get totalCount => individualTotal + campaignTotal;
  int get passedCount => individualPassed + campaignPassed;
  int get referredCount => individualReferred + campaignReferred;
  int get pendingCount => individualPending + campaignPending;

  Future<void> loadPatients() async {
    _loading = true;
    notifyListeners();

    final campaignRows = await _campaignRepository.getAllCampaigns();
    final allPatients = await _patientRepository.getPatients(pageSize: 500);
    final latestByPatient = await _screeningRepository.getLatestScreeningsForPatients(
      allPatients.map((row) => row['id'] as String),
    );

    final individualPatients = <PatientListItem>[];
    final campaignPatients = <PatientListItem>[];

    for (final row in allPatients) {
      final patientId = row['id'] as String;
      final latest = latestByPatient[patientId];
      final age = (row['age'] as int?) ?? 0;
      final patient = PatientListItem(
        initials: (row['name'] as String)
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0])
            .take(2)
            .join(),
        avatarGradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
        photoUrl: (row['photo_path'] as String?) ?? '',
        name: row['name'] as String,
        age: age,
        gender: row['gender'] as String,
        village: (row['village'] as String?) ?? '',
        ageGroup: age < 18
            ? 'child'
            : age > 60
            ? 'elderly'
            : 'adult',
        od: normaliseVisualAcuity(latest?['od_snellen'] as String?),
        os: normaliseVisualAcuity(latest?['os_snellen'] as String?),
        ou: normaliseVisualAcuity(latest?['ou_near_snellen'] as String?),
        outcome: (latest?['outcome'] as String?) ?? 'pending',
        date: latest?['screening_date'] != null
            ? formatPatientDate(latest!['screening_date'] as String)
            : 'Not screened',
        id: patientId,
        phone: (row['phone'] as String?) ?? '',
        facility: _nullIfEmpty(latest?['referral_facility'] as String?),
        referralStatus: _nullIfEmpty(latest?['referral_status'] as String?),
        campaignId: _nullIfEmpty(row['campaign_id'] as String?),
        conditions: ((row['conditions'] as String?) ?? '')
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      );

      if (patient.campaignId == null) {
        individualPatients.add(patient);
      } else {
        campaignPatients.add(patient);
      }
    }

    _patients = individualPatients;
    _campaigns = campaignRows;
    _allCampaignPatients = campaignPatients;
    _loading = false;
    notifyListeners();
  }

  Future<void> deleteCampaign(String campaignId) async {
    await _campaignRepository.deleteCampaign(campaignId);
    await loadPatients();
  }

  Future<void> deletePatient(String patientId) async {
    await _patientRepository.deletePatient(patientId);
    await loadPatients();
  }

  Future<void> updateReferralStatus(
    String patientId,
    String status,
  ) async {
    final screenings = await _screeningRepository.getScreeningsForPatient(
      patientId,
    );
    if (screenings.isEmpty) {
      return;
    }
    await _screeningRepository.updateReferralStatus(
      screenings.first['id'] as int,
      status,
    );
    await loadPatients();
  }

  Map<String, dynamic> findCampaignById(String? campaignId) {
    if (campaignId == null || campaignId.isEmpty) {
      return <String, dynamic>{};
    }
    return _campaigns.firstWhere(
      (campaign) => campaign['id'] == campaignId,
      orElse: () => <String, dynamic>{},
    );
  }

  static String formatPatientDate(String iso) {
    try {
      final dateTime = DateTime.parse(iso);
      final now = DateTime.now();
      if (dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day) {
        final difference = now.difference(dateTime);
        if (difference.inMinutes < 60) {
          return 'Today | ${difference.inMinutes}m ago';
        }
        return 'Today | ${difference.inHours}hr ago';
      }
      return '${dateTime.day} ${_month(dateTime.month)}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  static String _month(int month) => const [
    '',
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
  ][month];

  static String? _nullIfEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
