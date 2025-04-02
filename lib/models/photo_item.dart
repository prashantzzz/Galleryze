import 'package:flutter/services.dart';
import 'web_asset_entity.dart';
import '../services/thumbnail_service.dart';

class PhotoItem {
  final WebAssetEntity _asset;
  bool isFavorite;
  Set<String> categories;
  Uint8List? _cachedThumbData;
  Uint8List? _cachedFullData;

  PhotoItem({
    required WebAssetEntity webAsset,
    this.isFavorite = false,
    Set<String>? categories,
  }) : 
    _asset = webAsset,
    categories = categories ?? {};

  // Getters for asset properties
  String get id => _asset.id;
  String get title => _asset.title;
  String get url => _asset.url;
  DateTime get createDateTime => _asset.createDateTime;
  DateTime get modifiedDateTime => _asset.modifiedDateTime;
  int get size => _asset.size;

  // Get thumbnail data with caching
  Future<Uint8List?> get thumbData async {
    if (_cachedThumbData != null) return _cachedThumbData;
    
    try {
      _cachedThumbData = await ThumbnailService.generateThumbnail(_asset.url);
      return _cachedThumbData;
    } catch (e) {
      print('Error loading thumbnail: $e');
      return null;
    }
  }

  // Get full resolution image data with caching
  Future<Uint8List?> get fullData async {
    if (_cachedFullData != null) return _cachedFullData;
    
    try {
      final ByteData data = await rootBundle.load(_asset.url);
      _cachedFullData = data.buffer.asUint8List();
      return _cachedFullData;
    } catch (e) {
      print('Error loading full image: $e');
      return null;
    }
  }

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