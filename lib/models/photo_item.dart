import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoItem {
  final AssetEntity asset;
  bool isFavorite;
  final List<String> categories;

  PhotoItem({
    required this.asset,
    this.isFavorite = false,
    List<String>? categories,
  }) : categories = categories ?? [];

  PhotoItem copyWith({
    AssetEntity? asset,
    bool? isFavorite,
    List<String>? categories,
  }) {
    return PhotoItem(
      asset: asset ?? this.asset,
      isFavorite: isFavorite ?? this.isFavorite,
      categories: categories ?? List.from(this.categories),
    );
  }

  // Helper methods
  DateTime get createDateTime => asset.createDateTime;
  int get size => asset.size;
  String get id => asset.id;

  bool isInCategory(String category) {
    return categories.contains(category);
  }

  void addToCategory(String category) {
    if (!categories.contains(category)) {
      categories.add(category);
    }
  }

  void removeFromCategory(String category) {
    categories.remove(category);
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}
