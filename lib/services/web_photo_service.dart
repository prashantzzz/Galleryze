import '../models/web_asset_entity.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service for fetching photos on web platform
class WebPhotoService {
  /// Clear cached thumbnails
  static Future<void> clearCache() async {
    try {
      final cache = DefaultCacheManager();
      await cache.emptyCache();
      print('Thumbnail cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get a list of sample photos for web demo
  static Future<List<WebAssetEntity>> getSamplePhotos() async {
    final List<WebAssetEntity> photos = [];
    
    try {
      // Get the manifest content
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for images in the test directory
      final testImages = manifestMap.keys
          .where((String key) => key.startsWith('test/') && 
              (key.toLowerCase().endsWith('.jpg') || 
               key.toLowerCase().endsWith('.jpeg') ||
               key.toLowerCase().endsWith('.png')))
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort newest first

      print('Found ${testImages.length} images in test directory');

      // Verify each image actually exists by trying to load it
      List<String> validImages = [];
      for (final imagePath in testImages) {
        try {
          // Try to load the image - this will throw if it doesn't exist
          await rootBundle.load(imagePath);
          validImages.add(imagePath);
        } catch (e) {
          print('Image $imagePath no longer exists, skipping');
        }
      }
      
      print('Verified ${validImages.length} images exist');

      for (int i = 0; i < validImages.length; i++) {
        final assetPath = validImages[i];
        final filename = assetPath.split('/').last;
        final now = DateTime.now();
        final creationDate = now.subtract(Duration(days: i * 2));
        final modifiedDate = now.subtract(Duration(hours: i * 5));
        
        // Get asset size
        final ByteData data = await rootBundle.load(assetPath);
        final fileSize = data.lengthInBytes;
        
        photos.add(WebAssetEntity(
          id: 'local_$i',
          title: filename,
          url: assetPath, // Asset path
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