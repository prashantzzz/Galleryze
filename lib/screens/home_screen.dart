import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/photo_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/photo_grid.dart';

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
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<PhotoProvider>(context, listen: false).loadPhotos();
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading photos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galleryze'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                final photos = photoProvider.photos;
                return Column(
                  children: [
                    // Category selector
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip('all', 'All Photos'),
                          _buildCategoryChip('favorites', 'Favorites'),
                          _buildCategoryChip('recent', 'Recent'),
                        ],
                      ),
                    ),
                    // Photo grid
                    Expanded(
                      child: photos.isEmpty
                          ? Center(
                              child: Text(
                                _selectedCategory == 'favorites'
                                    ? 'No favorite photos yet'
                                    : 'No photos in this category',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : PhotoGrid(
                              photos: photos,
                              onDragToCategory: (photoId, categoryId) {
                                photoProvider.addPhotoToCategory(photoId, categoryId);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCategoryChip(String categoryId, String label) {
    final isSelected = _selectedCategory == categoryId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = categoryId;
          });
        },
      ),
    );
  }
}