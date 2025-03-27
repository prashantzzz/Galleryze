import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Categories',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: categories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.7),
                      child: Icon(category.icon, color: Colors.white),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: category.isDefault
                        ? const Text('Default category', style: TextStyle(fontStyle: FontStyle.italic))
                        : null,
                    trailing: category.isDefault
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              _showDeleteCategoryDialog(context, category);
                            },
                          ),
                    onTap: () {
                      if (!category.isDefault) {
                        _showEditCategoryDialog(context, category);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No custom categories',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add custom categories to organize your photos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            onPressed: () => _showAddCategoryDialog(null),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext? context) {
    if (context == null) return;
    
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
                _colorOption(Colors.blue, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.red, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.green, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.orange, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.purple, selectedColor, (color) {
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
                _iconOption(Icons.folder, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.favorite, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.star, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.photo, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.movie, selectedIcon, (icon) {
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
                _colorOption(Colors.blue, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.red, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.green, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.orange, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.purple, selectedColor, (color) {
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
                _iconOption(Icons.folder, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.favorite, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.star, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.photo, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.movie, selectedIcon, (icon) {
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
                final updatedCategory = Category(
                  id: category.id,
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

  void _showDeleteCategoryDialog(BuildContext context, Category category) {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}" category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  Widget _colorOption(Color color, Color selectedColor, Function(Color) onSelect) {
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

  Widget _iconOption(IconData icon, IconData selectedIcon, Function(IconData) onSelect) {
    final isSelected = icon.codePoint == selectedIcon.codePoint;
    return GestureDetector(
      onTap: () => onSelect(icon),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
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