import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('sharenova/native');

  /// Requests the necessary storage permissions based on the Android version.
  /// Uses MANAGE_EXTERNAL_STORAGE for Android 11+ and WRITE_EXTERNAL_STORAGE for below.
  static Future<bool> requestAllFilesPermission() async {
    if (!Platform.isAndroid) return true; // Only targeting Android here

    try {
      // Check if Android 11+ via native channel
      final isManager = await _channel.invokeMethod<bool>('checkManageExternalStorage');
      if (isManager != null) {
        if (!isManager) {
          // Request MANAGE_EXTERNAL_STORAGE
          final granted = await _channel.invokeMethod<bool>('requestManageExternalStorage');
          return granted ?? false;
        } else {
          return true; // Already granted
        }
      } else {
        // Not Android 11+, fallback to normal permission handler
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      // Fallback
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }
}
