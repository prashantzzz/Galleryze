import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionsHandler {
  // Request permission to access device photos
  static Future<bool> requestPermission() async {
    // On web, permissions are handled differently
    if (kIsWeb) {
      return true; // Web version uses demo images, so no need for permissions
    } else {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      return ps.isAuth;
    }
  }

  // Check if we have permission
  static Future<bool> hasPermission() async {
    if (kIsWeb) {
      return true;
    } else {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      return ps.isAuth;
    }
  }

  // Open app settings page if permission is permanently denied
  static Future<void> openSettings() async {
    if (!kIsWeb) {
      PhotoManager.openSetting();
    }
  }
}
