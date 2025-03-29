import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/photo_item.dart';
import '../providers/category_provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/photo_grid.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? _selectedCategoryId;
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_selectedCategoryId == null ? 'Categories' : 
          categoryProvider.getCategoryById(_selectedCategoryId!)?.name ?? ''),
        actions: [
          if (_selectedCategoryId == null)
            IconButton(
              icon: Icon(_editMode ? Icons.check : Icons.edit),
              onPressed: () {
                setState(() {
                  _editMode = !_editMode;
                });
              },
            ),
        ],
      ),
      body: _selectedCategoryId == null
          ? _buildCategoriesGrid(categoryProvider, photoProvider)
          : _buildCategoryPhotos(photoProvider),
    );
  }

  Widget _buildCategoriesGrid(CategoryProvider categoryProvider, PhotoProvider photoProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Favorites card
          _buildFavoritesCard(photoProvider),
          
          const SizedBox(height: 24.0),
          
          // Categories heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_editMode)
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                  onPressed: _showAddCategoryDialog,
                ),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // Categories grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.5,
            ),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              final photoCount = photoProvider
                  .getPhotosByCategory(category.id)
                  .length;
              
              return _buildCategoryCard(category, photoCount);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesCard(PhotoProvider photoProvider) {
    final favoriteCount = photoProvider.photos.where((p) => p.isFavorite).length;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = 'Favorites';
        });
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.favorite,
                size: 120,
                color: Colors.red.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 8.0),
                      Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '$favoriteCount items',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int photoCount) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = category.id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(category.icon, color: Colors.black87),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '$photoCount items',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_editMode && category.isEditable)
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCategoryDialog(category);
                    } else if (value == 'delete') {
                      _showDeleteCategoryDialog(category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPhotos(PhotoProvider photoProvider) {
    if (_selectedCategoryId == null) return const SizedBox.shrink();
    
    List<dynamic> photos;
    
    if (_selectedCategoryId == 'Favorites') {
      photos = photoProvider.photos.where((p) => p.isFavorite).toList();
    } else {
      photos = photoProvider.getPhotosByCategory(_selectedCategoryId!);
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${photos.length} items',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
                child: const Text(
                  'Back to Categories',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: photos.isEmpty
              ? Center(
                  child: Text(
                    _selectedCategoryId == 'Favorites'
                        ? 'No favorite photos yet'
                        : 'No photos in this category',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : PhotoGrid(
                  photos: photos.map((photo) => photo as PhotoItem).toList(),
                  onDragToCategory: (photoId, categoryId) {
                    photoProvider.addPhotoToCategory(photoId, categoryId);
                  },
                ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                categoryProvider.addCategoryFromNameAndIcon(nameController.text, Icons.folder);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final TextEditingController nameController = TextEditingController(text: category.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                final updatedCategory = category.copyWith(
                  name: nameController.text,
                );
                categoryProvider.updateCategory(updatedCategory);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
              categoryProvider.deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
