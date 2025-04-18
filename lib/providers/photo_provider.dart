import 'package:flutter/material.dart';
import '../models/photo_item.dart';
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

  String _sortBy = 'date';
  bool _sortAscending = false;
  
  // Add a key for forcing UI rebuilds
  int _sortChangeCounter = 0;
  int get sortChangeCounter => _sortChangeCounter;

  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Initialize and load photos from web service
  Future<void> loadPhotos({bool forceRefresh = false}) async {
    // If photos are already loaded and not forcing refresh, don't reload
    if (_photos.isNotEmpty && !forceRefresh) return;
    
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (forceRefresh) {
        // Clear thumbnail cache to ensure we're showing the latest images
        await WebPhotoService.clearCache();
        // Clear existing photos
        _photos.clear();
      }
      
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
    
    // Update the string-based sort properties for the new system
    switch (option) {
      case SortOption.dateAsc:
        _sortBy = 'date';
        _sortAscending = true;
        break;
      case SortOption.dateDesc:
        _sortBy = 'date';
        _sortAscending = false;
        break;
      case SortOption.sizeAsc:
        _sortBy = 'size';
        _sortAscending = true;
        break;
      case SortOption.sizeDesc:
        _sortBy = 'size';
        _sortAscending = false;
        break;
    }
    
    _applySorting();
    notifyListeners();
  }

  // Sort photos based on current sort option
  void _applySorting() {
    if (_photos.isEmpty) return;
    
    // print('Applying sorting: by $_sortBy, ascending: $_sortAscending');
    
    _photos.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case 'date':
          // Sort by creation date
          comparison = a.createDateTime.compareTo(b.createDateTime);
          // print('Comparing dates: ${a.createDateTime} vs ${b.createDateTime} = $comparison');
          break;
        case 'size':
          // Sort by file size
          comparison = a.size.compareTo(b.size);
          // print('Comparing sizes: ${a.size} vs ${b.size} = $comparison');
          break;
        default:
          comparison = 0;
      }
      
      // Apply sort direction
      return _sortAscending ? comparison : -comparison;
    });
    
    // Debug - print first few photos after sorting
    // if (_photos.isNotEmpty) {
    //   print('After sorting, first photo: ${_photos[0].title}, date: ${_photos[0].createDateTime}, size: ${_photos[0].size}');
    //   if (_photos.length > 1) {
    //     print('Second photo: ${_photos[1].title}, date: ${_photos[1].createDateTime}, size: ${_photos[1].size}');
    //   }
    // }
  }

  void setSortBy(String sortBy, bool ascending) {
    // print('setSortBy called with: sortBy=$sortBy, ascending=$ascending');
    // print('Before change: _sortBy=$_sortBy, _sortAscending=$_sortAscending');
    
    _sortBy = sortBy;
    _sortAscending = ascending;
    
    // Update the SortOption enum for compatibility
    if (sortBy == 'date') {
      _sortOption = ascending ? SortOption.dateAsc : SortOption.dateDesc;
    } else if (sortBy == 'size') {
      _sortOption = ascending ? SortOption.sizeAsc : SortOption.sizeDesc;
    }
    
    // print('After change: _sortBy=$_sortBy, _sortAscending=$_sortAscending, _sortOption=$_sortOption');
    
    _applySorting();
    
    // Increment counter to force UI rebuilds
    _sortChangeCounter++;
    
    notifyListeners();
    
    print('Sorting applied and listeners notified');
  }

  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    _applySorting();
    notifyListeners();
  }

  // Refresh images but preserve metadata like favorites and categories
  Future<void> refreshImages() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Clear thumbnail cache to ensure we're showing the latest images
      await WebPhotoService.clearCache();
      
      // Get the existing photo metadata (favorites, categories)
      Map<String, Map<String, dynamic>> photoMetadataByFilename = {};
      
      // Store metadata by filename for easier matching
      for (var photo in _photos) {
        String filename = photo.title; // Use the filename as key
        photoMetadataByFilename[filename] = {
          'isFavorite': photo.isFavorite,
          'categories': Set<String>.from(photo.categories), // Create a copy of the set
        };
      }
      
      // Debug
      // print('Saved metadata for ${photoMetadataByFilename.length} existing photos');
      // photoMetadataByFilename.forEach((filename, data) {
      //   print('- $filename: favorite=${data['isFavorite']}, categories=${data['categories']}');
      // });
      
      // Get the new photos
      final webAssets = await WebPhotoService.getSamplePhotos();
      print('Loaded ${webAssets.length} photos from WebPhotoService');
      
      // Create new photo items with updated metadata
      List<PhotoItem> newPhotos = [];
      
      for (var asset in webAssets) {
        // Create a new photo item
        var photo = PhotoItem(webAsset: asset);
        
        // Match by filename
        if (photoMetadataByFilename.containsKey(photo.title)) {
          // Restore metadata for existing photos
          var metadata = photoMetadataByFilename[photo.title]!;
          photo.isFavorite = metadata['isFavorite'] as bool;
          photo.categories = metadata['categories'] as Set<String>;
          // print('Restored metadata for ${photo.title}: favorite=${photo.isFavorite}, categories=${photo.categories}');
        } else {
          // This is a new photo
          print('New photo detected: ${photo.title}');
        }
        
        newPhotos.add(photo);
      }
      
      // Replace photos collection
      _photos = newPhotos;
      
      _applySorting();
      _error = null;
    } catch (e) {
      _error = 'Failed to load photos: $e';
      print('Error refreshing images: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
