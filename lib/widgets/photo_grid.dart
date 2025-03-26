import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/photo_item.dart';
import 'photo_tile.dart';

class PhotoGrid extends StatelessWidget {
  final List<dynamic> photos;
  final Function(String, String)? onDragToCategory;

  const PhotoGrid({
    Key? key,
    required this.photos,
    this.onDragToCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Text('No photos found in this category'),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      padding: const EdgeInsets.all(4.0),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        // Calculate a height (some taller, some shorter) for interesting grid layout
        final aspectRatio = index % 6 == 0 || index % 6 == 3 ? 0.8 : 1.2;
        
        return PhotoTile(
          photo: photo,
          aspectRatio: aspectRatio,
          onDragToCategory: onDragToCategory,
        );
      },
    );
  }
}
