import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/category_button.dart';
import '../widgets/photo_grid.dart';
import '../widgets/sort_dialog.dart';
import '../utils/permissions_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = '';
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
    
    await PermissionsHandler.requestPermission();
    
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.loadPhotos();
    
    setState(() {
      _isLoading = false;
    });
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
                categoryProvider.addCategory(nameController.text, Icons.folder);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => const SortDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Galleryze',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Sort funnel icon
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showSortDialog,
                      ),
                      // Pro button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Categories row
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: [
                  // Add button
                  GestureDetector(
                    onTap: _showAddCategoryDialog,
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  // Category buttons
                  ...categoryProvider.categories.map(
                    (category) => CategoryButton(
                      category: category,
                      isSelected: _selectedCategory == category.id,
                      onTap: () {
                        setState(() {
                          _selectedCategory = _selectedCategory == category.id ? '' : category.id;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Photo grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : photoProvider.photos.isEmpty
                      ? const Center(
                          child: Text('No photos found. Grant permission to access your photos.'),
                        )
                      : PhotoGrid(
                          photos: _selectedCategory.isEmpty
                              ? photoProvider.photos
                              : photoProvider.getPhotosByCategory(_selectedCategory),
                          onDragToCategory: (photoId, categoryId) {
                            photoProvider.addPhotoToCategory(photoId, categoryId);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
