/// Entity representing an image asset
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