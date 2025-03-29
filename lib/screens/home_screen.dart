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

  void _showSortOptions(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Date (Newest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.dateDesc);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Date (Oldest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.dateAsc);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Size (Largest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.sizeDesc);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Size (Smallest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.sizeAsc);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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

    // Then sort the filtered photos
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    switch (photoProvider.sortOption) {
      case SortOption.dateAsc:
        filteredPhotos.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
        break;
      case SortOption.dateDesc:
        filteredPhotos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
        break;
      case SortOption.sizeAsc:
        filteredPhotos.sort((a, b) => a.size.compareTo(b.size));
        break;
      case SortOption.sizeDesc:
        filteredPhotos.sort((a, b) => b.size.compareTo(a.size));
        break;
    }

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
              // Category selector with sort button
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Categories list
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
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
                    // Sort button
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: () => _showSortOptions(context),
                      tooltip: 'Sort photos',
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