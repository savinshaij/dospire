import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static RemoteConfigService? _instance;
  static RemoteConfigService get instance {
    _instance ??= RemoteConfigService();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          // Use a shorter interval for debug/dev builds to test changes quickly
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 12),
        ),
      );

      await _remoteConfig.setDefaults({
        'announcement_enabled': false,
        'announcement_title': 'Welcome to DoSpire!',
        'announcement_body': 'We have some exciting updates for you.',
        'announcement_image_url': '',
        'announcement_link': '',
        'announcement_id': '0', // Increment this in console to show again
      });

      await _remoteConfig.fetchAndActivate();
      debugPrint('Remote Config fetched and activated');
    } catch (e) {
      debugPrint('Remote Config fetch failed: $e');
    }
  }

  bool get isAnnouncementEnabled =>
      _remoteConfig.getBool('announcement_enabled');
  String get announcementTitle => _remoteConfig.getString('announcement_title');
  String get announcementBody => _remoteConfig.getString('announcement_body');
  String get announcementImageUrl =>
      _remoteConfig.getString('announcement_image_url');
  String get announcementLink => _remoteConfig.getString('announcement_link');
  String get announcementId => _remoteConfig.getString('announcement_id');
}
