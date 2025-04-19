import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_classifier_provider.dart';
import '../providers/photo_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AutoCategorizeButton extends StatelessWidget {
  const AutoCategorizeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final classifierProvider = Provider.of<ImageClassifierProvider>(context);
    final isProcessing = classifierProvider.isProcessing;
    final progress = classifierProvider.progress;

    return IconButton(
      icon: isProcessing 
          ? const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black54,
              ),
            )
          : const Icon(Icons.auto_awesome),
      tooltip: isProcessing ? 'Processing...' : 'Auto-Categorize',
      onPressed: isProcessing 
          ? null 
          : () => _startAutoCategorization(context),
    );
  }

  Future<void> _startAutoCategorization(BuildContext context) async {
    try {
      // Get the test directory path
      final testDir = Directory('test');
      String testDirPath;
      
      if (await testDir.exists()) {
        testDirPath = testDir.path;
      } else {
        // If test directory doesn't exist, use app documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        testDirPath = appDocDir.path;
        
        // Show a message that we're using the app documents directory
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test directory not found. Using app documents directory.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Initialize the classifier provider if not already initialized
      final classifierProvider = Provider.of<ImageClassifierProvider>(context, listen: false);
      await classifierProvider.initialize();
      
      // Show a snackbar to indicate processing has started
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting image categorization...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Process images in background
      await classifierProvider.processImagesInBackground(testDirPath);
      
      // Refresh the UI
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      photoProvider.refreshImages();
      
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Images categorized successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error categorizing images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
