import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
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
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color,
                        child: Icon(
                          category.icon,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: category.isDefault
                          ? const Chip(
                              label: Text('Default'),
                              backgroundColor: Colors.grey,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _showEditCategoryDialog(context, category);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _showDeleteConfirmation(context, category);
                                  },
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        child: const Icon(Icons.add),
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