import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Category {
  final String id;
  String name;
  IconData icon;
  bool isEditable;
  bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.isEditable = true,
    this.isDefault = false,
  });

  factory Category.create({
    required String name,
    required IconData icon,
    bool isEditable = true,
    bool isDefault = false,
  }) {
    return Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      isEditable: isEditable,
      isDefault: isDefault,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    bool? isEditable,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isEditable: isEditable ?? this.isEditable,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
