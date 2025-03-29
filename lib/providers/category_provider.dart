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
    
    // Add a few custom categories for demonstration
    _categories.addAll([
      Category(
        id: 'vacation',
        name: 'Vacation',
        icon: Icons.beach_access,
        color: Colors.orange,
      ),
      Category(
        id: 'family',
        name: 'Family',
        icon: Icons.family_restroom,
        color: Colors.green,
      ),
      Category(
        id: 'food',
        name: 'Food',
        icon: Icons.restaurant,
        color: Colors.amber,
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