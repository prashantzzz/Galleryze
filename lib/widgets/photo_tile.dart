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
  
  @override
  void didUpdateWidget(PhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the photo has changed or its favorite status has changed, reload the thumbnail
    if (widget.photo.id != oldWidget.photo.id || 
        widget.photo.isFavorite != oldWidget.photo.isFavorite) {
      _loadThumbnail();
    }
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
          _hasError = thumbData == null;
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
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              PhotoViewScreen(photo: widget.photo),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var beginScale = 0.9;
              var endScale = 1.0;
              
              // Create a curved animation for smoother transition
              var curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuart,
              );
              
              return Stack(
                children: [
                  // Add a background color transition
                  FadeTransition(
                    opacity: curvedAnimation,
                    child: Container(color: Colors.black),
                  ),
                  // Add a scale and position transition for the content
                  ScaleTransition(
                    scale: Tween<double>(
                      begin: beginScale,
                      end: endScale
                    ).animate(curvedAnimation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                ],
              );
            },
            transitionDuration: const Duration(milliseconds: 250),
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
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_hasError) 
            const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 16),
            )
          else
            Hero(
              tag: 'photo_${widget.photo.id}',
              child: MemoryImage(_thumbnail!) is ImageProvider
                  ? Image(
                      image: MemoryImage(_thumbnail!),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    )
                  : Image.memory(
                      _thumbnail!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    ),
            ),

          // Like button in top right corner
          Positioned(
            top: 4,
            right: 4,
            child: Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                return IconButton(
                  icon: Icon(
                    widget.photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  iconSize: 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    photoProvider.toggleFavorite(widget.photo.id);
                  },
                );
              },
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
