import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
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
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  void _loadThumbnail() {
    _thumbnailFuture = widget.photo.asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
      quality: 80,
    );
  }

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
          child: FutureBuilder<Uint8List?>(
            future: _thumbnailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && 
                  snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              } else {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey),
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
                child: FutureBuilder<Uint8List?>(
                  future: _thumbnailFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && 
                        snapshot.data != null) {
                      return GestureDetector(
                        onTap: () {
                          _showPhotoDetails(context);
                        },
                        child: Hero(
                          tag: 'photo_${widget.photo.id}',
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 8.0,
            right: 8.0,
            child: GestureDetector(
              onTap: () {
                final photoProvider = Provider.of<PhotoProvider>(
                  context, 
                  listen: false,
                );
                photoProvider.toggleFavorite(widget.photo.id);
              },
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  widget.photo.isFavorite 
                      ? Icons.favorite 
                      : Icons.favorite_border,
                  color: widget.photo.isFavorite 
                      ? Colors.red 
                      : Colors.white,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40.0,
                  height: 5.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: widget.photo.asset.thumbnailDataWithSize(
                          ThumbnailSize(
                            MediaQuery.of(context).size.width.toInt(),
                            (MediaQuery.of(context).size.width * 1.2).toInt(),
                          ),
                          quality: 90,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && 
                              snapshot.data != null) {
                            return Hero(
                              tag: 'photo_${widget.photo.id}',
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            return Container(
                              height: MediaQuery.of(context).size.width * 1.2,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Photo Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            _buildDetailItem(
                              'Date',
                              _formatDate(widget.photo.createDateTime),
                            ),
                            const Divider(),
                            _buildDetailItem(
                              'Size',
                              _formatFileSize(widget.photo.size),
                            ),
                            const Divider(),
                            _buildDetailItem(
                              'Categories',
                              widget.photo.categories.isEmpty
                                  ? 'None'
                                  : widget.photo.categories.join(', '),
                            ),
                            const SizedBox(height: 24.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.favorite,
                                  label: widget.photo.isFavorite 
                                      ? 'Remove Favorite' 
                                      : 'Add to Favorites',
                                  color: widget.photo.isFavorite 
                                      ? Colors.red 
                                      : Colors.black,
                                  onTap: () {
                                    final photoProvider = Provider.of<PhotoProvider>(
                                      context, 
                                      listen: false,
                                    );
                                    photoProvider.toggleFavorite(widget.photo.id);
                                    Navigator.pop(context);
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.edit,
                                  label: 'Edit Categories',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showCategoriesDialog(context);
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.share,
                                  label: 'Share',
                                  onTap: () {
                                    // Implement share functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Share functionality coming soon!'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6.0),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context) {
    // Implement a dialog to edit photo categories
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Categories'),
        content: const Text(
          'Drag and drop this photo to a category on the home screen to add it to that category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
