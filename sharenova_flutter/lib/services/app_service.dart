// ignore_for_file: unused_import, avoid_print, use_build_context_synchronously

import 'package:device_apps/device_apps.dart';

/// Service to fetch installed applications on Android devices.
/// iOS does not expose a list of installed apps, so this service is a no‑op there.
class AppService {
  /// Returns a list of installed applications.
  /// Each app provides its name, package name and icon (as a Uint8List).
  Future<List<Application>> getInstalledApps() async {
    try {
      // `includeAppIcons: true` fetches the app icon as a Uint8List.
      // This can be a heavy operation; in a production app you might want to
      // cache the results or load icons lazily.
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
      );
      return apps;
    } catch (e) {
      print('Error fetching installed apps: $e');
      return [];
    }
  }
}
