import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/photo_grid.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/auto_categorize_button.dart';

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
            onPressed: () {
              context.read<PhotoProvider>().refreshImages();
            },
          ),
          const SortDropdown(),
          const AutoCategorizeButton(),
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