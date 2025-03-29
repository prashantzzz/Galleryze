import '../models/web_asset_entity.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Service for fetching photos on web platform
class WebPhotoService {
  /// Get a list of sample photos for web demo
  static Future<List<WebAssetEntity>> getSamplePhotos() async {
    final List<WebAssetEntity> photos = [];
    
    try {
      // Get the test directory path
      final testDir = Directory('test');
      
      if (!await testDir.exists()) {
        print('Test directory not found');
        return photos;
      }

      // List all files in the test directory
      final List<FileSystemEntity> files = await testDir.list().toList();
      
      // Filter for image files and sort by name (newest first)
      final imageFiles = files
          .where((file) => file is File && 
              (file.path.toLowerCase().endsWith('.jpg') || 
               file.path.toLowerCase().endsWith('.jpeg') ||
               file.path.toLowerCase().endsWith('.png')))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // Sort newest first

      print('Found ${imageFiles.length} images in test directory');

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i] as File;
        final filename = path.basename(file.path);
        final now = DateTime.now();
        final creationDate = now.subtract(Duration(days: i * 2));
        final modifiedDate = now.subtract(Duration(hours: i * 5));
        
        // Get actual file size
        final fileSize = await file.length();
        
        photos.add(WebAssetEntity(
          id: 'local_$i',
          title: filename,
          url: 'test/$filename', // Asset path
          createDateTime: creationDate,
          modifiedDateTime: modifiedDate,
          width: 800,
          height: 600,
          size: fileSize,
          mimeType: 'image/jpeg',
        ));
      }

      print('Created ${photos.length} local photo entities');
    } catch (e) {
      print('Error loading images from test directory: $e');
    }
    
    return photos;
  }
}