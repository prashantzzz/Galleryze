import 'package:flutter/material.dart';
import '../models/photo_item.dart';
import 'photo_tile.dart';

class PhotoGrid extends StatelessWidget {
  final List<PhotoItem> photos;
  final Function(String, String)? onDragToCategory;

  const PhotoGrid({
    Key? key,
    required this.photos,
    this.onDragToCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 500, // Cache more items for smoother scrolling
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: PhotoTile(
              key: ValueKey('photo_${photo.id}'),
              photo: photo,
              onDragToCategory: onDragToCategory,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No photos found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Photos you add to this category will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}