import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Category> get categories => _categories;
  
  // Initialize with default categories
  CategoryProvider() {
    _initializeDefaultCategories();
  }

  void _initializeDefaultCategories() {
    _categories = [
      Category(
        id: 'food',
        name: 'Food',
        icon: Icons.restaurant,
        isEditable: false,
        isDefault: true,
      ),
      Category(
        id: 'people',
        name: 'People',
        icon: Icons.people,
        isEditable: false,
        isDefault: true,
      ),
      Category(
        id: 'pets',
        name: 'Pets',
        icon: Icons.pets,
        isEditable: false,
        isDefault: true,
      ),
      Category(
        id: 'docs',
        name: 'Docs',
        icon: Icons.description,
        isEditable: false,
        isDefault: true,
      ),
      Category(
        id: 'nature',
        name: 'Nature',
        icon: Icons.nature,
        isEditable: false,
        isDefault: true,
      ),
    ];
  }

  // Add a new custom category
  void addCategory(String name, IconData icon) {
    final newCategory = Category.create(
      name: name,
      icon: icon,
      isEditable: true,
      isDefault: false,
    );
    
    _categories.add(newCategory);
    notifyListeners();
  }

  // Update an existing category
  void updateCategory(String id, {String? name, IconData? icon}) {
    final index = _categories.indexWhere((category) => category.id == id);
    
    if (index != -1 && _categories[index].isEditable) {
      if (name != null) {
        _categories[index].name = name;
      }
      
      if (icon != null) {
        _categories[index].icon = icon;
      }
      
      notifyListeners();
    }
  }

  // Delete a category
  void deleteCategory(String id) {
    final index = _categories.indexWhere((category) => category.id == id);
    
    if (index != -1 && _categories[index].isEditable && !_categories[index].isDefault) {
      _categories.removeAt(index);
      notifyListeners();
    }
  }

  // Get a category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get a category by name
  Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((category) => 
          category.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}
