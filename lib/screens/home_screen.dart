import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/photo_grid.dart';
import '../widgets/sort_dropdown.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load photos after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoProvider>().loadPhotos();
    });
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
      appBar: AppBar(
        title: const Text('GalleryZen'),
        actions: [
          const SortDropdown(),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
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
                    onPressed: () => photoProvider.loadPhotos(),
                    child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

          if (photoProvider.photos.isEmpty) {
            return const Center(
              child: Text('No photos found'),
            );
          }

          return Column(
            children: [
              // Category chips section without the duplicate sort button
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              // Photo grid
              Expanded(
                child: _getFilteredAndSortedPhotos(photoProvider.photos, _selectedCategory).isEmpty
                    ? Center(
                        child: Text(
                          _selectedCategory == 'favorites'
                              ? 'No favorite photos yet'
                              : 'No photos in this category',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : PhotoGrid(
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

  Widget _buildCategoryChip(String categoryId, String label, IconData icon, Color color) {
    final isSelected = _selectedCategory.toLowerCase() == categoryId.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? color : Colors.grey[600],
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: color.withOpacity(0.1),
        backgroundColor: Colors.grey[200],
        showCheckmark: false,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = categoryId;
          });
        },
      ),
    );
  }
}