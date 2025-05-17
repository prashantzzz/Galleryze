import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';
import '../providers/category_provider.dart';
import '../providers/image_classifier_provider.dart';
import '../widgets/photo_grid.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/auto_categorize_button.dart';
import '../widgets/image_classifier_status_widget.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    // Load photos after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoProvider>().loadPhotos(context: context);
    });
  }

  // Force UI refresh when classification completes
  void _refreshUI() {
    setState(() {});
  }

  // Get filtered and sorted photos based on category
  List<PhotoItem> _getFilteredAndSortedPhotos(List<PhotoItem> allPhotos, String categoryId) {
    if (allPhotos.isEmpty) {
      return [];
    }
    
    // First filter photos based on category
    List<PhotoItem> filteredPhotos;
    if (categoryId.toLowerCase() == 'all') {
      filteredPhotos = allPhotos;
    } else if (categoryId.toLowerCase() == 'favorites') {
      filteredPhotos = allPhotos.where((photo) => photo.isFavorite).toList();
    } else {
      filteredPhotos = allPhotos.where((photo) => photo.isInCategory(categoryId)).toList();
    }

    // Use the PhotoProvider's current sort settings 
    // (the provider already sorts its photos, but we need to sort our filtered subset)
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final sortBy = photoProvider.sortBy;
    final ascending = photoProvider.sortAscending;
    final sortChangeCounter = photoProvider.sortChangeCounter;
    
    filteredPhotos.sort((a, b) {
      int comparison;
      
      switch (sortBy) {
        case 'date':
          comparison = a.createDateTime.compareTo(b.createDateTime);
          break;
        case 'size':
          comparison = a.size.compareTo(b.size);
          break;
        default:
          comparison = 0;
      }
      
      return ascending ? comparison : -comparison;
    });

    return filteredPhotos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'GalleryZen',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Show reset confirmation dialog
              final bool shouldReset = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Options'),
                  content: const Text('Do you want to reset all categories and reload photos?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Just Refresh'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
              ) ?? false;
              
              if (shouldReset) {
                await _resetAll(context);
              } else {
                // Just refresh photos
                context.read<PhotoProvider>().loadPhotos(forceRefresh: true, context: context);
                _refreshUI();
              }
            },
          ),
          const SortDropdown(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Consumer<ImageClassifierProvider>(
              builder: (context, provider, child) {
                return AutoCategorizeButton(
                  onClassificationCompleted: _refreshUI,
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          // Force rebuild on sort changes
          final sortBy = photoProvider.sortBy;
          final sortAscending = photoProvider.sortAscending;
          final sortChangeCounter = photoProvider.sortChangeCounter;
          
          if (photoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (photoProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    photoProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => photoProvider.loadPhotos(context: context),
                    child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

          if (photoProvider.photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No photos found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please grant storage permission to view your photos',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => photoProvider.loadPhotos(context: context, forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Category chips section with minimal design
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ...Provider.of<CategoryProvider>(context).categories.map((category) => 
                        _buildCategoryChip(
                          category.id,
                          category.name,
                          category.icon,
                          category.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add the image classifier status widget
              const ImageClassifierStatusWidget(),
              // Photo grid
              Expanded(
                child: _getFilteredAndSortedPhotos(photoProvider.photos, _selectedCategory).isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedCategory == 'favorites' ? Icons.favorite_border : Icons.photo_library_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory == 'favorites'
                                ? 'No favorite photos yet'
                                : 'No photos in this category',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            _selectedCategory == 'favorites'
                              ? Text(
                                  'Tap the heart icon on photos to add them to favorites',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  textAlign: TextAlign.center,
                                )
                              : const SizedBox.shrink(),
                          ],
                        ),
                      )
                    : PhotoGrid(
                        key: ValueKey('photo_grid_${sortChangeCounter}_$_selectedCategory'),
                        photos: _getFilteredAndSortedPhotos(photoProvider.photos, _selectedCategory),
                        onDragToCategory: (photoId, categoryId) {
                          Provider.of<PhotoProvider>(context, listen: false).addPhotoToCategory(photoId, categoryId);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Reset all categories and reload photos
  Future<void> _resetAll(BuildContext context) async {
    try {
      // Show a loading indicator
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Resetting all categories...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Reset the image classifier provider
      final classifierProvider = Provider.of<ImageClassifierProvider>(context, listen: false);
      await classifierProvider.resetClassifier();
      
      // Reset the photo provider (clear categories)
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      await photoProvider.resetCategories();
      
      // Clear the application support directory
      try {
        final appDir = await getApplicationSupportDirectory();
        final mlKitDir = Directory('${appDir.path}/ml_kit');
        if (await mlKitDir.exists()) {
          await mlKitDir.delete(recursive: true);
          print('DEBUG: Deleted ML Kit directory');
        }
      } catch (e) {
        print('DEBUG: Error clearing ML Kit directory: $e');
        // Continue even if this fails
      }
      
      // Reload photos
      await photoProvider.loadPhotos(forceRefresh: true, context: context);
      
      // Show success message
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('All categories have been reset'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Refresh the UI
      _refreshUI();
    } catch (e) {
      print('DEBUG: Error in resetAll: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCategoryChip(String categoryId, String label, IconData icon, Color color) {
    final isSelected = _selectedCategory.toLowerCase() == categoryId.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = categoryId;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.grey[850]! : Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  spreadRadius: 0,
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}