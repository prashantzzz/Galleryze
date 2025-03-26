import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'web_asset_entity.dart';
import 'package:http/http.dart' as http;

class PhotoItem {
  final dynamic _asset; // Can be AssetEntity or WebAssetEntity
  bool isFavorite;
  Set<String> categories;
  Uint8List? _cachedThumbData;

  PhotoItem({
    AssetEntity? asset,
    WebAssetEntity? webAsset,
    this.isFavorite = false,
    Set<String>? categories,
  }) : 
    _asset = asset ?? webAsset,
    categories = categories ?? {} {
    assert(asset != null || webAsset != null, 'Either asset or webAsset must be provided');
  }

  String get id => _asset is AssetEntity ? _asset.id : (_asset as WebAssetEntity).id;
  DateTime get createDateTime => _asset is AssetEntity 
    ? _asset.createDateTime 
    : (_asset as WebAssetEntity).createDateTime;
  int get size => _asset is AssetEntity ? _asset.size : (_asset as WebAssetEntity).size;

  // Fetch thumbnail data
  Future<Uint8List?> get thumbData async {
    if (_cachedThumbData != null) return _cachedThumbData;
    
    if (_asset is AssetEntity) {
      _cachedThumbData = await _asset.thumbnailData;
      return _cachedThumbData;
    } else {
      // For web, fetch the image from URL
      final webAsset = _asset as WebAssetEntity;
      try {
        final response = await http.get(Uri.parse(webAsset.url));
        if (response.statusCode == 200) {
          _cachedThumbData = response.bodyBytes;
          return _cachedThumbData;
        }
      } catch (e) {
        print('Error loading image: $e');
      }
      return null;
    }
  }
  
  // Fetch original image data
  Future<Uint8List?> get originBytes async {
    if (_asset is AssetEntity) {
      return _asset.originBytes;
    } else {
      // For web, use the same data as thumbnail for simplicity
      return thumbData;
    }
  }

  // URL for web assets
  String? get url => _asset is WebAssetEntity ? (_asset as WebAssetEntity).url : null;

  // Toggle favorite status
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  // Add photo to category
  void addToCategory(String category) {
    categories.add(category);
  }

  // Remove photo from category
  void removeFromCategory(String category) {
    categories.remove(category);
  }

  // Check if photo is in category
  bool isInCategory(String category) {
    return categories.contains(category);
  }
}