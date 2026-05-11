import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_constants.dart';

class ChwProfileData {
  const ChwProfileData({
    required this.name,
    required this.center,
    required this.chwId,
    required this.photoPath,
    required this.referralLanguage,
  });

  final String name;
  final String center;
  final String chwId;
  final String photoPath;
  final String referralLanguage;

  String get title => center.isNotEmpty
      ? 'Community Health Worker - $center'
      : 'Community Health Worker';
}

class ChwProfilePreferences {
  ChwProfilePreferences._();

  static Future<ChwProfileData> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ChwProfileData(
      name: prefs.getString(AppStrings.prefChwName) ?? '',
      center: prefs.getString(AppStrings.prefChwCenter) ?? '',
      chwId: prefs.getString(AppStrings.prefChwId) ?? '',
      photoPath: prefs.getString(AppStrings.prefChwPhoto) ?? '',
      referralLanguage:
          prefs.getString(AppStrings.prefReferralLanguage) ?? 'English Only',
    );
  }
}
