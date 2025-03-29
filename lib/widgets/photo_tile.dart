import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';

class PhotoTile extends StatefulWidget {
  final PhotoItem photo;
  final double aspectRatio;
  final Function(String, String)? onDragToCategory;

  const PhotoTile({
    Key? key,
    required this.photo,
    this.aspectRatio = 1.0,
    this.onDragToCategory,
  }) : super(key: key);

  @override
  _PhotoTileState createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: widget.photo.id,
      feedback: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: FutureBuilder<dynamic>(
            future: widget.photo.thumbData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && 
                  snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              } else {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ),
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: GestureDetector(
                  onTap: () {
                    _showPhotoDetails(context);
                  },
                  child: Hero(
                    tag: 'photo_${widget.photo.id}',
                    child: FutureBuilder<dynamic>(
                      future: widget.photo.thumbData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && 
                            snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        } else {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Favorite badge
          if (widget.photo.isFavorite)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 16,
                ),
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
