import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';

class PhotoTile extends StatefulWidget {
  final PhotoItem photo;
  final double aspectRatio;
  final Function(String, String)? onDragToCategory;
  final VoidCallback? onTap;

  const PhotoTile({
    Key? key,
    required this.photo,
    this.aspectRatio = 1.0,
    this.onDragToCategory,
    this.onTap,
  }) : super(key: key);

  @override
  _PhotoTileState createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showPhotoDetails(context);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: widget.photo.thumbData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                );
              }

              return Hero(
                tag: 'photo_${widget.photo.id}',
                child: FadeInImage(
                  placeholder: MemoryImage(snapshot.data!),
                  image: MemoryImage(snapshot.data!),
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 300),
                  imageErrorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error_outline, color: Colors.red),
                    );
                  },
                ),
              );
            },
          ),
          if (widget.photo.isFavorite)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  // Show photo details (full screen)
  void _showPhotoDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoDetailsScreen(photo: widget.photo),
      ),
    );
  }
}

class _PhotoDetailsScreen extends StatelessWidget {
  final PhotoItem photo;

  const _PhotoDetailsScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<PhotoProvider>(
            builder: (context, photoProvider, child) {
              return IconButton(
                icon: Icon(
                  photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: () {
                  photoProvider.toggleFavorite(photo.id);
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: 'photo_${photo.id}',
          child: FutureBuilder<dynamic>(
            future: photo.thumbData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && 
                  snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
