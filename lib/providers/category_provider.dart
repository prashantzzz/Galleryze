import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Category> get categories => _categories;
  
  // Initialize with default categories
  CategoryProvider() {
    _loadCategories();
  }
  
  void _loadCategories() {
    // In a real app, these might be loaded from SharedPreferences
    _categories = Category.getDefaultCategories();
    
    // Add custom categories
    _categories.addAll([
      const Category(
        id: 'documents',
        name: 'Documents',
        icon: Icons.description,
        color: Colors.orange,
        isDefault: true,
        isEditable: false,
      ),
      const Category(
        id: 'people',
        name: 'People',
        icon: Icons.family_restroom,
        color: Colors.green,
        isDefault: true,
        isEditable: false,
      ),
      const Category(
        id: 'animals',
        name: 'Animals',
        icon: Icons.pets,
        color: Colors.purple,
        isDefault: true,
        isEditable: false,
      ),
      const Category(
        id: 'nature',
        name: 'Nature',
        icon: Icons.landscape,
        color: Colors.teal,
        isDefault: true,
        isEditable: false,
      ),
      const Category(
        id: 'food',
        name: 'Food',
        icon: Icons.restaurant,
        color: Colors.amber,
        isDefault: true,
        isEditable: false,
      ),
      const Category(
        id: 'others',
        name: 'Others',
        icon: Icons.label,
        color: Colors.grey,
        isDefault: true,
        isEditable: false,
      ),
    ]);
    notifyListeners();
  }
  
  // Add a new category
  void addCategory(Category category) {
    // Check if category with the same ID already exists
    if (_categories.any((c) => c.id == category.id)) {
      return;
    }
    
    _categories.add(category);
    notifyListeners();
    // In a real app, save categories to SharedPreferences
  }
  
  // Update an existing category
  void updateCategory(Category updatedCategory) {
    final index = _categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index != -1) {
      // Don't allow editing default categories
      if (_categories[index].isDefault) {
        return;
      }
      _categories[index] = updatedCategory;
      notifyListeners();
      // In a real app, save categories to SharedPreferences
    }
  }
  
  // Delete a category
  void deleteCategory(String categoryId) {
    // Don't allow deleting default categories
    if (_categories.any((c) => c.id == categoryId && c.isDefault)) {
      return;
    }
    
    _categories.removeWhere((c) => c.id == categoryId);
    notifyListeners();
    // In a real app, save categories to SharedPreferences
  }
  
  // Get a category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Add a new category from name and icon
  void addCategoryFromNameAndIcon(String name, IconData icon) {
    final category = Category(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      icon: icon,
      color: Colors.blue, // Default color
      isDefault: false,
      isEditable: true,
    );
    addCategory(category);
  }
}