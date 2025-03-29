import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';
import '../screens/photo_view_screen.dart';

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
  Uint8List? _thumbnail;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final thumbData = await widget.photo.thumbData;
      if (mounted) {
        setState(() {
          _thumbnail = thumbData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoViewScreen(photo: widget.photo),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_hasError) 
            const Center(
              child: Icon(Icons.error_outline, color: Colors.red),
            )
          else
            Hero(
              tag: 'photo_${widget.photo.id}',
              child: Image.memory(
                _thumbnail!,
                fit: BoxFit.cover,
              ),
            ),

          // Like button in top right corner
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Consumer<PhotoProvider>(
                builder: (context, photoProvider, child) {
                  return IconButton(
                    icon: Icon(
                      widget.photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    iconSize: 22,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      photoProvider.toggleFavorite(widget.photo.id);
                    },
                  );
                },
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
