import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isDefault;
  final bool isEditable;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isEditable = true,
  });

  // Create a copy of this category with new values
  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isDefault,
    bool? isEditable,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isEditable: isEditable ?? this.isEditable,
    );
  }

  // Create a category from JSON data
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      color: Color(json['colorValue'] as int),
      isDefault: json['isDefault'] as bool? ?? false,
      isEditable: json['isEditable'] as bool? ?? true,
    );
  }

  // Convert this category to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'isDefault': isDefault,
      'isEditable': isEditable,
    };
  }

  // Default categories
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'all',
        name: 'All Photos',
        icon: Icons.photo_library,
        color: Colors.blue,
        isDefault: true,
        isEditable: false,
      ),
      Category(
        id: 'favorites',
        name: 'Favorites',
        icon: Icons.favorite,
        color: Colors.red,
        isDefault: true,
        isEditable: false,
      ),
      Category(
        id: 'recent',
        name: 'Recent',
        icon: Icons.access_time,
        color: Colors.purple,
        isDefault: true,
        isEditable: false,
      ),
    ];
  }
}