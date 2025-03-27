import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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

    return DragTarget<String>(
      onAccept: (categoryId) {
        // This is for receiving a category being dragged to a photo
        // Not implemented in this version
      },
      builder: (context, candidateData, rejectedData) {
        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          padding: const EdgeInsets.all(4),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            // Alternate aspect ratios for a more interesting grid
            final aspectRatio = index % 3 == 0 ? 0.8 : (index % 5 == 0 ? 1.5 : 1.0);
            
            return PhotoTile(
              photo: photo,
              aspectRatio: aspectRatio,
              onDragToCategory: onDragToCategory,
            );
          },
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