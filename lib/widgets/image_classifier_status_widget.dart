import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_classifier_provider.dart';

class ImageClassifierStatusWidget extends StatelessWidget {
  const ImageClassifierStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final classifierProvider = Provider.of<ImageClassifierProvider>(context);
    
    if (classifierProvider.isProcessing) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Classifying images...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: classifierProvider.progress,
                backgroundColor: Colors.grey[200],
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                '${(classifierProvider.progress * 100).toStringAsFixed(1)}% complete',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (classifierProvider.error != null) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Error classifying images',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      classifierProvider.clearError();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                classifierProvider.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  classifierProvider.initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox(); // Nothing to show when not processing and no error
  }
} 