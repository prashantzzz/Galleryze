import 'dart:typed_data';

/// Web implementation that mimics AssetEntity from photo_manager package
class WebAssetEntity {
  final String id;
  final String title;
  final DateTime createDateTime;
  final DateTime modifiedDateTime;
  final int width;
  final int height;
  final int size; // in bytes
  final String? mimeType;
  final String url;

  WebAssetEntity({
    required this.id,
    required this.title,
    required this.createDateTime,
    required this.modifiedDateTime,
    required this.width,
    required this.height,
    required this.size,
    this.mimeType,
    required this.url,
  });

  // Methods to mimic AssetEntity
  Future<Uint8List?> get thumbData async {
    // This would normally fetch a thumbnail from the web
    // For demonstration purposes, this would be handled by the WebPhotoService
    return null;
  }

  Future<Uint8List?> get fullData async {
    // This would normally fetch the full image data from the web
    // For demonstration purposes, this would be handled by the WebPhotoService
    return null;
  }

  // Create a sample WebAssetEntity with demo data
  factory WebAssetEntity.sample({
    required String id,
    required String url,
  }) {
    return WebAssetEntity(
      id: id,
      title: 'Sample Image $id',
      createDateTime: DateTime.now().subtract(Duration(days: int.parse(id))),
      modifiedDateTime: DateTime.now().subtract(Duration(hours: int.parse(id))),
      width: 800,
      height: 600,
      size: 1024 * 1024 * 2, // 2MB
      mimeType: 'image/jpeg',
      url: url,
    );
  }
}