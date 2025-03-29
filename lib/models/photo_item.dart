import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'web_asset_entity.dart';

class PhotoItem {
  final WebAssetEntity _asset;
  bool isFavorite;
  Set<String> categories;
  Uint8List? _cachedThumbData;

  PhotoItem({
    required WebAssetEntity webAsset,
    this.isFavorite = false,
    Set<String>? categories,
  }) : 
    _asset = webAsset,
    categories = categories ?? {};

  String get id => _asset.id;
  DateTime get createDateTime => _asset.createDateTime;
  int get size => _asset.size;

  // Fetch thumbnail data
  Future<Uint8List?> get thumbData async {
    if (_cachedThumbData != null) return _cachedThumbData;
    
    try {
      print('Loading image from asset: ${_asset.url}');
      // Load asset image data
      _cachedThumbData = await rootBundle.load(_asset.url)
          .then((byteData) => byteData.buffer.asUint8List());
      print('Successfully loaded image: ${_asset.url}');
      return _cachedThumbData;
    } catch (e) {
      print('Error loading image: $e');
    }
    return null;
  }
  
  // Fetch original image data
  Future<Uint8List?> get originBytes async {
    return thumbData;
  }

  // Asset path for local images
  String get url => _asset.url;

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
    return categories.any((c) => c.toLowerCase() == category.toLowerCase());
  }
}