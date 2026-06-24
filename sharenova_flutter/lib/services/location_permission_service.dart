import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service to request location permission required for Wi‑Fi Direct discovery.
/// On web, permission handling is bypassed since it's not supported.
class LocationPermissionService {
  /// Requests fine location permission. Returns true if granted or on web.
  static Future<bool> requestLocationPermission() async {
    // On web platform, permission handling is different/not supported
    // Return true to allow the app to continue on web
    if (kIsWeb) return true;

    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }
}