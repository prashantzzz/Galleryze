import 'dart:typed_data';
import 'web_asset_entity.dart';
import 'package:http/http.dart' as http;

class PhotoItem {
  final WebAssetEntity _asset; // Using WebAssetEntity for all platforms for simplicity
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
      final response = await http.get(Uri.parse(_asset.url));
      if (response.statusCode == 200) {
        _cachedThumbData = response.bodyBytes;
        return _cachedThumbData;
      }
    } catch (e) {
      print('Error loading image: $e');
    }
    return null;
  }
  
  // Fetch original image data
  Future<Uint8List?> get originBytes async {
    // Use the same data as thumbnail for simplicity
    return thumbData;
  }

  // URL for web assets
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
    return categories.contains(category);
  }
}