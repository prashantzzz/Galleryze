import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_classifier_provider.dart';
import '../providers/photo_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class AutoCategorizeButton extends StatelessWidget {
  final VoidCallback? onClassificationCompleted;
  
  const AutoCategorizeButton({
    Key? key, 
    this.onClassificationCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final classifierProvider = Provider.of<ImageClassifierProvider>(context);
    final isProcessing = classifierProvider.isProcessing;
    final progress = classifierProvider.progress;

    return IconButton(
      icon: isProcessing 
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 20, 
                      height: 20, 
              child: CircularProgressIndicator(
                strokeWidth: 2,
                        value: progress > 0 ? progress : null,
                color: Colors.black54,
              ),
                    ),
                    if (progress > 0)
                      Text(
                        '${(progress * 100).toInt()}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
            )
          : const Icon(Icons.auto_awesome),
      tooltip: isProcessing ? 'Classifying images...' : 'Classify with ML Kit',
      onPressed: isProcessing 
          ? null 
          : () => _startAutoCategorization(context),
    );
  }
  
  // Reset functionality has been moved to HomeScreen

  // Check and request storage permissions
  Future<bool> _checkStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // First check if permission is already granted
      final status = await Permission.photos.status;
      if (status.isGranted) {
        print('DEBUG: Storage permission already granted');
        return true;
      }
      
      // On Android, show an explanation dialog before requesting permissions
      final bool userAccepted = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Permission Required'),
          content: const Text(
            'To classify your images, this app needs access to your device storage to read images from your device. Please grant storage permission on the next screen.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!userAccepted) {
        return false;
      }
      
      // Request storage permissions using permission_handler
      final newStatus = await Permission.photos.request();
      print('DEBUG: Permission status: $newStatus');
      
      if (newStatus.isDenied) {
        // Show a dialog explaining how to enable permissions
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text(
              'Storage permission was denied. The app cannot access your images without this permission. Please enable it in app settings.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await AppSettings.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return false;
      }
      
      if (newStatus.isPermanentlyDenied) {
        // Show a dialog instructing the user to enable permissions from settings
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Permanently Denied'),
            content: const Text(
              'Storage permission was permanently denied. Please enable it from the app settings to access your images.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await AppSettings.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return false;
      }
      
      return newStatus.isGranted;
    }
    
    // For non-Android platforms
    return true;
  }

  Future<void> _startAutoCategorization(BuildContext context) async {
    try {
      // First check permissions
      final hasPermission = await _checkStoragePermission(context);
      if (!hasPermission) {
        print('DEBUG: Storage permission not granted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to access your images'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Show a dialog explaining what's happening
      final bool proceed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Classify Images'),
          content: const Text(
            'This will analyze your images in the Downloads folder using Google ML Kit Image Labeling and categorize them based on their content. The process may take a while depending on the number of images.\n\nDo you want to proceed?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!proceed) return;

      // Get the classifier provider
      final classifierProvider = Provider.of<ImageClassifierProvider>(context, listen: false);
      
      // Try to use the Downloads folder
      String? imagesPath = classifierProvider.imagesPath;
      
      if (imagesPath == null) {
        print('DEBUG: Images path is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access image folder'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      print('DEBUG: Using images path: $imagesPath');
      
      // Check if there are images in the directory
      try {
        final dir = Directory(imagesPath);
        final files = await dir.list().toList();
        final imageFiles = files.whereType<File>().where((file) {
          final ext = file.path.toLowerCase();
          return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || 
                 ext.endsWith('.png') || ext.endsWith('.gif');
        }).toList();
        
        if (imageFiles.isEmpty) {
          print('DEBUG: No images found in $imagesPath');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No image files found in $imagesPath. Please add some JPG images to your Downloads folder.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        
        print('DEBUG: Found ${imageFiles.length} images to process');
        print('DEBUG: First image path: ${imageFiles.isNotEmpty ? imageFiles.first.path : "none"}');
        
        // Initialize the classifier
        await classifierProvider.initialize();
        print('DEBUG: Classifier initialized successfully');
      
      // Show a snackbar to indicate processing has started
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting ML Kit image classification on ${imageFiles.length} images from Downloads folder...'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Process images
        print('DEBUG: About to call processImagesAndUpdateCategories');
        await classifierProvider.processImagesAndUpdateCategories(imagesPath);
        print('DEBUG: Finished processing images');
        
        // Refresh the UI
        final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
        photoProvider.refreshImages();
        
        // Call the completion callback if provided
        if (onClassificationCompleted != null) {
          onClassificationCompleted!();
        }
        
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images classified successfully with ML Kit!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Print debugging information about categories
        final categories = ['Documents', 'People', 'Animals', 'Nature', 'Food', 'Others'];
        for (final category in categories) {
          final count = photoProvider.getPhotosByCategory(category).length;
          print('Category $category has $count photos');
        }
      } catch (e) {
        print('DEBUG ERROR: Error processing images: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading images: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show an error message
      print('DEBUG ERROR: General error in _startAutoCategorization: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error classifying images: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Directory search functionality has been removed
}
