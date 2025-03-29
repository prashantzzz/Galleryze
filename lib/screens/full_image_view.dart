import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/photo_item.dart';

class FullImageView extends StatelessWidget {
  final PhotoItem photo;

  const FullImageView({
    Key? key,
    required this.photo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                return const Center(
                  child: Icon(Icons.error_outline, color: Colors.red, size: 48),
                );
              }

              // Show full resolution image with smooth transition
              return Hero(
                tag: 'photo_${photo.id}',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
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