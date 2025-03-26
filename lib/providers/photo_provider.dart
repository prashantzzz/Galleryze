import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_item.dart';
import '../utils/permissions_handler.dart';

enum SortOption { dateAsc, dateDesc, sizeAsc, sizeDesc }

class PhotoProvider extends ChangeNotifier {
  List<PhotoItem> _photos = [];
  List<PhotoItem> get photos => _photos;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _error = '';
  String get error => _error;
  
  SortOption _sortOption = SortOption.dateDesc;
  SortOption get sortOption => _sortOption;

  // Initialize and load photos from device
  Future<void> loadPhotos() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final permissionGranted = await PermissionsHandler.requestPermission();
      
      if (!permissionGranted) {
        _error = 'Permission denied to access photos';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get all albums/folders
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );
      
      // Get the all photos album
      if (albums.isNotEmpty) {
        final AssetPathEntity allPhotosAlbum = albums.first;
        
        // Load photos from the album
        final List<AssetEntity> assetList = await allPhotosAlbum.getAssetListRange(
          start: 0,
          end: 1000, // Limit to 1000 photos for performance
        );
        
        // Map assets to PhotoItem model
        _photos = assetList.map((asset) => PhotoItem(asset: asset)).toList();
        
        // Apply default sorting
        _sortPhotos();
      }
    } catch (e) {
      _error = 'Failed to load photos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more photos (for pagination)
  Future<void> loadMorePhotos() async {
    // Implementation for loading more photos when reaching the end of the list
  }

  // Toggle favorite status
  void toggleFavorite(String photoId) {
    final index = _photos.indexWhere((photo) => photo.id == photoId);
    if (index != -1) {
      _photos[index].toggleFavorite();
      notifyListeners();
    }
  }

  // Get photos by category
  List<PhotoItem> getPhotosByCategory(String category) {
    if (category == 'Favorites') {
      return _photos.where((photo) => photo.isFavorite).toList();
    }
    return _photos.where((photo) => photo.isInCategory(category)).toList();
  }

  // Add photo to category
  void addPhotoToCategory(String photoId, String category) {
    final index = _photos.indexWhere((photo) => photo.id == photoId);
    if (index != -1) {
      _photos[index].addToCategory(category);
      notifyListeners();
    }
  }

  // Remove photo from category
  void removePhotoFromCategory(String photoId, String category) {
    final index = _photos.indexWhere((photo) => photo.id == photoId);
    if (index != -1) {
      _photos[index].removeFromCategory(category);
      notifyListeners();
    }
  }

  // Set sort option and apply sorting
  void setSortOption(SortOption option) {
    _sortOption = option;
    _sortPhotos();
    notifyListeners();
  }

  // Sort photos based on current sort option
  void _sortPhotos() {
    switch (_sortOption) {
      case SortOption.dateAsc:
        _photos.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
        break;
      case SortOption.dateDesc:
        _photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
        break;
      case SortOption.sizeAsc:
        _photos.sort((a, b) => a.size.compareTo(b.size));
        break;
      case SortOption.sizeDesc:
        _photos.sort((a, b) => b.size.compareTo(a.size));
        break;
    }
  }
}
