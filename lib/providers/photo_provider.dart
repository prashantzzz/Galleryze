import 'package:flutter/material.dart';
import '../models/photo_item.dart';
import '../services/web_photo_service.dart';

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

  // Initialize and load photos from web service
  Future<void> loadPhotos() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Use web implementation for all platforms
      _photos = WebPhotoService.getSamplePhotos();
      _sortPhotos();
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
    if (category == 'favorites') {
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
