import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ThumbnailService {
  static const int THUMBNAIL_SIZE = 256;
  static const int THUMBNAIL_QUALITY = 85;

  static Future<Uint8List?> generateThumbnail(String imagePath) async {
    try {
      // Get the cached thumbnail if it exists
      final cache = DefaultCacheManager();
      final cacheKey = 'thumb_$imagePath';
      final cachedFile = await cache.getFileFromCache(cacheKey);
      
      if (cachedFile != null) {
        return await cachedFile.file.readAsBytes();
      }

      Uint8List originalBytes;
      
      // Check if this is a file path or an asset path
      if (imagePath.startsWith('/')) {
        // This is a file path
        final file = File(imagePath);
        if (await file.exists()) {
          originalBytes = await file.readAsBytes();
        } else {
          throw Exception('File does not exist: $imagePath');
        }
      } else {
        // This is an asset path
        final ByteData imageData = await rootBundle.load(imagePath);
        originalBytes = imageData.buffer.asUint8List();
      }

      // Compress the image
      final Uint8List compressedImage = await FlutterImageCompress.compressWithList(
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
      print('Error generating thumbnail for $imagePath: $e');
      return null;
    }
  }
} 