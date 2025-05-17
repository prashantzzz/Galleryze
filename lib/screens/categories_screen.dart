import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/photo_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final photoProvider = Provider.of<PhotoProvider>(context);
    final categories = categoryProvider.categories.where((c) => c.id != 'all').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your photo categories',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: categories.length + 1, // +1 for the add category tile
                itemBuilder: (context, index) {
                  // Last item is the add category tile
                  if (index == categories.length) {
                    return _buildAddCategoryTile(context);
                  }
                  
                  final category = categories[index];
                  final photoCount = photoProvider.getPhotosByCategory(category.id).length;
                  
                  return _buildCategoryTile(context, category, photoCount);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.folder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select a color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _buildColorOption(Colors.blue, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.red, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.green, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.orange, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.purple, selectedColor, (color) {
                  selectedColor = color;
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select an icon:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 15,
              children: [
                _buildIconOption(Icons.folder, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.favorite, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.star, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.photo, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.movie, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newCategory = Category(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  icon: selectedIcon,
                  color: selectedColor,
                );
                categoryProvider.addCategory(newCategory);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    Color selectedColor = category.color;
    IconData selectedIcon = category.icon;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select a color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _buildColorOption(Colors.blue, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.red, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.green, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.orange, selectedColor, (color) {
                  selectedColor = color;
                }),
                _buildColorOption(Colors.purple, selectedColor, (color) {
                  selectedColor = color;
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select an icon:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 15,
              children: [
                _buildIconOption(Icons.folder, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.favorite, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.star, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.photo, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _buildIconOption(Icons.movie, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedCategory = category.copyWith(
                  name: nameController.text,
                  icon: selectedIcon,
                  color: selectedColor,
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

  void _showDeleteConfirmation(BuildContext context, Category category) {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? '
            'Photos in this category will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              categoryProvider.deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category, int photoCount) {
    return GestureDetector(
      onTap: () {
        if (!category.isDefault && category.isEditable) {
          _showEditCategoryDialog(context, category);
        }
      },
      onLongPress: () {
        if (!category.isDefault && category.isEditable) {
          _showDeleteConfirmation(context, category);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Center icon
            Center(
              child: Icon(
                category.icon,
                color: category.color,
                size: 48,
              ),
            ),
            
            // Category name at the bottom
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: category.color.withOpacity(0.8),
                ),
              ),
            ),
            
            // Photo count at the bottom right
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  photoCount.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: category.color,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            
            // Edit button for custom categories
            if (!category.isDefault && category.isEditable)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () {
                      _showEditCategoryDialog(context, category);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showAddCategoryDialog(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add_circle_outline,
            color: Colors.grey,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, Color selectedColor, Function(Color) onSelect) {
    final isSelected = color.value == selectedColor.value;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : Container(),
      ),
    );
  }

  Widget _buildIconOption(IconData icon, IconData selectedIcon, Function(IconData) onSelect) {
    final isSelected = icon.codePoint == selectedIcon.codePoint;
    return GestureDetector(
      onTap: () => onSelect(icon),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}