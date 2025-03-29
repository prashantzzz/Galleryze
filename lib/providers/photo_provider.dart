import 'package:flutter/material.dart';
import '../models/photo_item.dart';
import '../models/web_asset_entity.dart';
import '../services/web_photo_service.dart';

enum SortOption { dateAsc, dateDesc, sizeAsc, sizeDesc }

class PhotoProvider extends ChangeNotifier {
  List<PhotoItem> _photos = [];
  List<PhotoItem> get photos => _photos;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  SortOption _sortOption = SortOption.dateDesc;
  SortOption get sortOption => _sortOption;

  String _sortBy = 'date'; // 'date', 'name', 'size'
  bool _sortAscending = false;

  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Initialize and load photos from web service
  Future<void> loadPhotos() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final webAssets = await WebPhotoService.getSamplePhotos();
      _photos = webAssets.map((asset) => PhotoItem(webAsset: asset)).toList();
      _applySorting();
      _error = null;
    } catch (e) {
      _error = 'Failed to load photos: $e';
      print('Error loading photos: $e');
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
    print('Getting photos for category: $category');
    print('Total photos available: ${_photos.length}');
    
    if (category.toLowerCase() == 'favorites') {
      final favorites = _photos.where((photo) => photo.isFavorite).toList();
      print('Found ${favorites.length} favorites');
      return favorites;
    }
    
    if (category.toLowerCase() == 'all') {
      print('Returning all ${_photos.length} photos');
      return _photos;
    }
    
    final categoryPhotos = _photos.where((photo) => 
      photo.categories.any((c) => c.toLowerCase() == category.toLowerCase())
    ).toList();
    print('Found ${categoryPhotos.length} photos in category $category');
    return categoryPhotos;
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
    _applySorting();
    notifyListeners();
  }

  // Sort photos based on current sort option
  void _applySorting() {
    if (_photos.isEmpty) return;
    
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

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applySorting();
    notifyListeners();
  }

  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    _applySorting();
    notifyListeners();
  }
}
