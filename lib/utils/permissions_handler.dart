import 'package:photo_manager/photo_manager.dart';

class PermissionsHandler {
  // Request permission to access device photos
  static Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  // Check if we have permission
  static Future<bool> hasPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  // Open app settings page if permission is permanently denied
  static Future<void> openSettings() async {
    PhotoManager.openSetting();
  }
}
