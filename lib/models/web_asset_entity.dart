import 'dart:math';

/// A web-specific implementation that mimics the behavior of AssetEntity from photo_manager
/// for compatibility between mobile and web platforms.
class WebAssetEntity {
  final String id;
  final String url; // URL to the image (local or remote)
  final DateTime createDateTime;
  final int size; // Size in bytes
  final int width;
  final int height;

  const WebAssetEntity({
    required this.id,
    required this.url,
    required this.createDateTime,
    required this.size,
    required this.width,
    required this.height,
  });

  // Create a mock web asset with a default image
  factory WebAssetEntity.demo({
    required String id,
    String? imageUrl,
  }) {
    final random = Random();
    final now = DateTime.now();
    final daysAgo = random.nextInt(365);
    
    return WebAssetEntity(
      id: id,
      url: imageUrl ?? 'https://picsum.photos/seed/$id/800/600', // Use Lorem Picsum for demo images
      createDateTime: now.subtract(Duration(days: daysAgo)),
      size: random.nextInt(5000000) + 500000, // Random size between 500KB and 5MB
      width: 800,
      height: 600,
    );
  }
  
  // Create from JSON for storage/retrieval
  factory WebAssetEntity.fromJson(Map<String, dynamic> json) {
    return WebAssetEntity(
      id: json['id'] as String,
      url: json['url'] as String,
      createDateTime: DateTime.parse(json['createDateTime'] as String),
      size: json['size'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'createDateTime': createDateTime.toIso8601String(),
      'size': size,
      'width': width,
      'height': height,
    };
  }
}