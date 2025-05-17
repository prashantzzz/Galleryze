import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../models/web_asset_entity.dart';

class DevicePhotoService {
  static bool _hasPermission = false;

  /// Check if the app has permission to access photos
  static Future<bool> hasStoragePermission() async {
    if (_hasPermission) return true;
    
    final status = await Permission.photos.status;
    _hasPermission = status.isGranted;
    return _hasPermission;
  }

  /// Request permission to access photos
  static Future<bool> requestStoragePermission(BuildContext? context) async {
    if (await hasStoragePermission()) return true;
    
    final status = await Permission.photos.request();
    _hasPermission = status.isGranted;
    
    if (!_hasPermission && context != null && status.isPermanentlyDenied) {
      // Show dialog to open app settings
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Photos Permission Required'),
          content: const Text(
            'To use Galleryze as your gallery app, please grant access to your photos in the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      
      if (shouldOpenSettings == true) {
        await AppSettings.openAppSettings();
      }
    }
    
    return _hasPermission;
  }

  /// Scan device storage for images
  static Future<List<WebAssetEntity>> getDevicePhotos({
    int limit = 100,
    int offset = 0,
  }) async {
    final List<WebAssetEntity> photos = [];
    
    if (!await hasStoragePermission()) {
      return photos;
    }
    
    try {
      // Common directories where photos are typically stored
      final List<Directory> directories = [];
      
      // Add DCIM directory
      final Directory? dcimDir = await _getPublicDirectory('DCIM');
      if (dcimDir != null) directories.add(dcimDir);
      
      // Add Pictures directory
      final Directory? picturesDir = await _getPublicDirectory('Pictures');
      if (picturesDir != null) directories.add(picturesDir);
      
      // Add Downloads directory
      final Directory? downloadsDir = await _getPublicDirectory('Download');
      if (downloadsDir != null) directories.add(downloadsDir);
      
      // Find image files in these directories
      List<FileSystemEntity> allFiles = [];
      for (final dir in directories) {
        try {
          final files = await _getFilesInDirectory(dir);
          allFiles.addAll(files);
        } catch (e) {
          debugPrint('Error scanning directory ${dir.path}: $e');
        }
      }
      
      // Filter for image files
      final imageFiles = allFiles
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .toList();
      
      // Sort by modified date (newest first)
      imageFiles.sort((a, b) {
        try {
          return b.statSync().modified.compareTo(a.statSync().modified);
        } catch (e) {
          return 0;
        }
      });
      
      // Apply pagination
      final paginatedFiles = imageFiles.skip(offset).take(limit).toList();
      
      // Convert to WebAssetEntity objects
      for (int i = 0; i < paginatedFiles.length; i++) {
        final file = paginatedFiles[i];
        final fileStat = file.statSync();
        
        photos.add(WebAssetEntity(
          id: 'device_${file.path.hashCode}',
          title: path.basename(file.path),
          url: file.path,
          createDateTime: fileStat.changed,
          modifiedDateTime: fileStat.modified,
          width: 0, // These will be determined when loading the image
          height: 0,
          size: fileStat.size,
          mimeType: _getMimeType(file.path),
        ));
      }
      
      debugPrint('Found ${photos.length} photos on device');
    } catch (e) {
      debugPrint('Error scanning device for photos: $e');
    }
    
    return photos;
  }

  /// Get a public directory path
  static Future<Directory?> _getPublicDirectory(String folderName) async {
    try {
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/$folderName');
        if (await directory.exists()) {
          return directory;
        }
      }
      // For iOS, we would use the photos permission instead
      return null;
    } catch (e) {
      debugPrint('Error getting public directory $folderName: $e');
      return null;
    }
  }

  /// Get all files in a directory and its subdirectories
  static Future<List<FileSystemEntity>> _getFilesInDirectory(Directory directory) async {
    List<FileSystemEntity> files = [];
    
    try {
      final entities = await directory.list(recursive: true).toList();
      files.addAll(entities);
    } catch (e) {
      debugPrint('Error listing files in ${directory.path}: $e');
    }
    
    return files;
  }

  /// Check if a file is an image based on its extension
  static bool _isImageFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.gif' || ext == '.webp';
  }

  /// Get MIME type based on file extension
  static String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
