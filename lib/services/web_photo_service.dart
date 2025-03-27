import '../models/photo_item.dart';
import '../models/web_asset_entity.dart';

/// Service for fetching photos on web platform
class WebPhotoService {
  /// Get a list of sample photos for web demo
  static List<PhotoItem> getSamplePhotos() {
    final List<PhotoItem> photos = [];
    
    // URLs for sample images (using placeholder image services)
    final List<String> sampleImageUrls = [
      'https://picsum.photos/id/1/800/600',
      'https://picsum.photos/id/2/800/600',
      'https://picsum.photos/id/3/800/600',
      'https://picsum.photos/id/4/800/600',
      'https://picsum.photos/id/5/800/600',
      'https://picsum.photos/id/6/800/600',
      'https://picsum.photos/id/7/800/600',
      'https://picsum.photos/id/8/800/600',
      'https://picsum.photos/id/9/800/600',
      'https://picsum.photos/id/10/800/600',
      'https://picsum.photos/id/11/800/600',
      'https://picsum.photos/id/12/800/600',
      'https://picsum.photos/id/13/800/600',
      'https://picsum.photos/id/14/800/600',
      'https://picsum.photos/id/15/800/600',
      'https://picsum.photos/id/16/800/600',
      'https://picsum.photos/id/17/800/600',
      'https://picsum.photos/id/18/800/600',
      'https://picsum.photos/id/19/800/600',
      'https://picsum.photos/id/20/800/600',
    ];
    
    // Create photo items with web asset entities
    for (int i = 0; i < sampleImageUrls.length; i++) {
      final WebAssetEntity webAsset = WebAssetEntity.demo(
        id: i.toString(),
        imageUrl: sampleImageUrls[i],
      );
      
      photos.add(PhotoItem(webAsset: webAsset));
    }
    
    return photos;
  }
}