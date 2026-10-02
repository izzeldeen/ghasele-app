import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

/// Forced-update check against `GET /api/app-version`.
///
/// The server holds, per platform, the lowest build number still allowed to run (the
/// number after "+" in pubspec.yaml) and the store link. Raising it there is how a
/// release is made mandatory - nothing in the app changes.
class AppUpdateService {
  /// The store link when this build is below the minimum, otherwise null.
  ///
  /// Fails open: no network, a slow or broken server, or an unknown platform all return
  /// null and the app starts as usual. Locking every customer out because the API is down
  /// would be far worse than letting an old build through for one launch.
  static Future<String?> requiredUpdateUrl() async {
    final String platform;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      platform = 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      platform = 'android';
    } else {
      return null;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/app-version?platform=$platform'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final minimumBuild = (body['minimumBuild'] as num?)?.toInt() ?? 0;
      final storeUrl = body['storeUrl'] as String? ?? '';

      if (minimumBuild > 0 && currentBuild < minimumBuild && storeUrl.isNotEmpty) {
        return storeUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Update check skipped: $e');
      return null;
    }
  }
}
