import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../models/photo_item.dart';

class PhotoViewScreen extends StatelessWidget {
  final PhotoItem photo;

  const PhotoViewScreen({
    Key? key,
    required this.photo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          photo.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: FutureBuilder<Uint8List?>(
            future: photo.fullData, // Load full resolution image
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show thumbnail while loading full image
                return FutureBuilder<Uint8List?>(
                  future: photo.thumbData,
                  builder: (context, thumbSnapshot) {
                    if (thumbSnapshot.hasData) {
                      return Hero(
                        tag: 'photo_${photo.id}',
                        child: Image.memory(
                          thumbSnapshot.data!,
                          fit: BoxFit.contain,
                        ),
                      );
                    }
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading image: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              // Show full resolution image with smooth transition
              return Hero(
                tag: 'photo_${photo.id}',
                child: PhotoView(
                  imageProvider: MemoryImage(snapshot.data!),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 