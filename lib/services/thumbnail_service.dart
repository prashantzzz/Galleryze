import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ThumbnailService {
  static const int THUMBNAIL_SIZE = 256;
  static const int THUMBNAIL_QUALITY = 85;

  static Future<Uint8List?> generateThumbnail(String assetPath) async {
    try {
      // Get the cached thumbnail if it exists
      final cache = DefaultCacheManager();
      final cacheKey = 'thumb_$assetPath';
      final cachedFile = await cache.getFileFromCache(cacheKey);
      
      if (cachedFile != null) {
        return await cachedFile.file.readAsBytes();
      }

      // Load the original image
      final ByteData imageData = await rootBundle.load(assetPath);
      final Uint8List originalBytes = imageData.buffer.asUint8List();

      // Compress the image
      final Uint8List? compressedImage = await FlutterImageCompress.compressWithList(
        originalBytes,
        minHeight: THUMBNAIL_SIZE,
        minWidth: THUMBNAIL_SIZE,
        quality: THUMBNAIL_QUALITY,
      );

      if (compressedImage != null) {
        // Cache the thumbnail
        await cache.putFile(
          cacheKey,
          compressedImage,
          key: cacheKey,
        );
      }

      return compressedImage;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }
} 