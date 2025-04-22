import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_classifier_provider.dart';
import '../providers/photo_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/image_classifier_service.dart';
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
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
        ),
        // Add a small menu button for options
        IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          tooltip: 'Classification Options',
          onPressed: isProcessing ? null : () => _showResetOptions(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
      ],
    );
  }
  
  Future<void> _showResetOptions(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    
    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'diag',
          child: Row(
            children: [
              Icon(Icons.search, size: 18),
              SizedBox(width: 8),
              Text('Find Image Directories'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'custom',
          child: Row(
            children: [
              Icon(Icons.folder, size: 18),
              SizedBox(width: 8),
              Text('Enter Custom Directory'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18),
              SizedBox(width: 8),
              Text('Reset Classification History'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'resetjson',
          child: Row(
            children: [
              Icon(Icons.update, size: 18),
              SizedBox(width: 8),
              Text('Reclassify After JSON Update'),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'reset') {
        await _resetClassificationTimestamp(context);
      } else if (value == 'diag') {
        await _runDiagnosticSearch(context);
      } else if (value == 'custom') {
        await _enterCustomDirectory(context);
      } else if (value == 'resetjson') {
        await _reclassifyAfterJsonUpdate(context);
      }
    });
  }
  
  Future<void> _resetClassificationTimestamp(BuildContext context) async {
    try {
      // Show a dialog to confirm
      final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset Classification History'),
          content: const Text(
            'This will clear the timestamp record and force all images to be re-classified on the next scan. Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        ),
      ) ?? false;
      
      if (confirm) {
        // Reset the checkpoint
        await ImageClassifierService.resetCheckpoint();
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classification history has been reset. All images will be re-classified on next scan.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('DEBUG ERROR: Failed to reset classification timestamp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting classification history: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Check and request storage permissions
  Future<bool> _checkStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
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
      final status = await Permission.photos.request();
      print('DEBUG: Permission status: $status');
      
      if (status.isDenied) {
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
      
      if (status.isPermanentlyDenied) {
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
      
      return status.isGranted;
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

  // Diagnostic search for image directories
  Future<void> _runDiagnosticSearch(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Searching for Images'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning device for image directories...\nPlease wait, this may take some time.'),
          ],
        ),
      ),
    );
    
    try {
      // Try specific paths that commonly contain images on Android devices
      final specificPaths = [
        '/storage/emulated/0/DCIM/Camera',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/sdcard/DCIM/Camera',
        '/sdcard/Pictures',
        '/sdcard/Download',
        '/sdcard/DCIM',
        '/storage/self/primary/DCIM/Camera',
        '/storage/self/primary/Pictures',
        '/storage/self/primary/Download',
        '/storage/self/primary/DCIM',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Images',
        '/storage/emulated/0/Pictures/Screenshots',
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images',
        '/storage/emulated/0/Telegram/Telegram Images',
      ];
      
      // The base directories to search recursively
      final commonDirs = [
        '/storage/emulated/0',
        '/sdcard',
        '/storage/self/primary',
      ];
      
      List<String> foundImageDirs = [];
      
      // First check specific paths directly
      print('DEBUG: Checking specific known image paths...');
      for (final path in specificPaths) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            print('DEBUG: Directory exists: $path');
            
            // Check if there are any images in this directory
            final entities = await directory.list().toList();
            final imageFiles = entities.whereType<File>().where((file) {
              final extension = file.path.toLowerCase();
              return extension.endsWith('.jpg') || extension.endsWith('.jpeg') || 
                     extension.endsWith('.png') || extension.endsWith('.gif') ||
                     extension.endsWith('.bmp');
            }).toList();
            
            if (imageFiles.isNotEmpty) {
              print('DEBUG: Found ${imageFiles.length} images in $path');
              foundImageDirs.add('$path (${imageFiles.length} images)');
            } else {
              print('DEBUG: No images found in $path');
            }
          } else {
            print('DEBUG: Directory does not exist: $path');
          }
        } catch (e) {
          print('DEBUG: Error checking $path: $e');
        }
      }
      
      // Then do deeper search if we haven't found anything yet
      if (foundImageDirs.isEmpty) {
        print('DEBUG: No images found in common locations, doing deeper search...');
        for (final baseDir in commonDirs) {
          try {
            final directory = Directory(baseDir);
            if (await directory.exists()) {
              // Search for image files in this directory and subdirectories
              await _scanForImages(directory, 0, 3, foundImageDirs);
            }
          } catch (e) {
            print('DEBUG: Error scanning $baseDir: $e');
          }
        }
      }
      
      // Close the progress dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show the results dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Image Directories Found'),
            content: foundImageDirs.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No directories with images were found.'),
                      const SizedBox(height: 12),
                      const Text('Try one of these paths:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _useCustomDirectory(context, '/storage/emulated/0/DCIM/Camera');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('/storage/emulated/0/DCIM/Camera', style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _useCustomDirectory(context, '/storage/emulated/0/Pictures');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('/storage/emulated/0/Pictures', style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _useCustomDirectory(context, '/storage/emulated/0/Download');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('/storage/emulated/0/Download', style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.maxFinite,
                    height: 250,
                    child: ListView.builder(
                      itemCount: foundImageDirs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(foundImageDirs[index]),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _useCustomDirectory(context, foundImageDirs[index]);
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _enterCustomDirectory(context);
                },
                child: const Text('Enter Custom Path'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning for images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Recursive function to scan for image directories
  Future<void> _scanForImages(Directory directory, int currentDepth, int maxDepth, List<String> results) async {
    if (currentDepth > maxDepth) return;
    
    try {
      bool hasImages = false;
      int imageCount = 0;
      
      // Check if this directory has images
      final entities = await directory.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          final extension = entity.path.toLowerCase();
          if (extension.endsWith('.jpg') || extension.endsWith('.jpeg') || 
              extension.endsWith('.png') || extension.endsWith('.gif') || 
              extension.endsWith('.bmp')) {
            hasImages = true;
            imageCount++;
          }
        }
      }
      
      if (hasImages && imageCount > 0) {
        print('DEBUG: Found directory with $imageCount images: ${directory.path}');
        results.add('${directory.path} ($imageCount images)');
      }
      
      // Check subdirectories if we're not at max depth
      if (currentDepth < maxDepth) {
        for (final entity in entities) {
          if (entity is Directory) {
            await _scanForImages(entity, currentDepth + 1, maxDepth, results);
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error scanning directory ${directory.path}: $e');
    }
  }
  
  // Allow user to enter a custom directory path
  Future<void> _enterCustomDirectory(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    final String? dirPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Directory Path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the full path to a directory containing images:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '/storage/emulated/0/DCIM/Camera',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Example paths:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('/storage/emulated/0/DCIM/Camera'),
            const Text('/storage/emulated/0/Pictures'),
            const Text('/sdcard/Download'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Use This Directory'),
          ),
        ],
      ),
    );
    
    if (dirPath != null && dirPath.isNotEmpty) {
      await _useCustomDirectory(context, dirPath);
    }
  }
  
  // Use a custom directory for image classification
  Future<void> _useCustomDirectory(BuildContext context, String dirPath) async {
    try {
      // Extract just the path part if it contains a count in parentheses
      final String cleanPath = dirPath.contains('(')
          ? dirPath.substring(0, dirPath.lastIndexOf('(')).trim()
          : dirPath;
      
      // Try multiple variations of the path
      List<String> pathVariations = [
        cleanPath,
        'raw:$cleanPath',
      ];
      
      if (cleanPath.startsWith('/storage/emulated/0/')) {
        // Try sdcard variation
        pathVariations.add('/sdcard/' + cleanPath.substring('/storage/emulated/0/'.length));
      }
      
      if (cleanPath.startsWith('/sdcard/')) {
        // Try storage/emulated variation
        pathVariations.add('/storage/emulated/0/' + cleanPath.substring('/sdcard/'.length));
      }
      
      bool found = false;
      List<File> imageFiles = [];
      String workingPath = '';
      
      // Try each path variation
      for (final path in pathVariations) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            print('DEBUG: Directory exists: $path');
            final entities = await directory.list().toList();
            imageFiles = entities.whereType<File>().where((file) {
              final extension = file.path.toLowerCase();
              return extension.endsWith('.jpg') || extension.endsWith('.jpeg') || 
                    extension.endsWith('.png') || extension.endsWith('.gif') ||
                    extension.endsWith('.bmp');
            }).toList();
            
            if (imageFiles.isNotEmpty) {
              print('DEBUG: Found ${imageFiles.length} images in $path');
              found = true;
              workingPath = path;
              break;
            }
          }
        } catch (e) {
          print('DEBUG: Error checking path variation $path: $e');
        }
      }
      
      if (!found || imageFiles.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No images found in any variation of: $cleanPath'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Show confirmation with image count
      if (context.mounted) {
        final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Directory'),
            content: Text('Found ${imageFiles.length} images in $workingPath.\n\nDo you want to use this directory for classification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Use This Directory'),
              ),
            ],
          ),
        ) ?? false;
        
        if (confirm) {
          // Use this directory for classification
          final classifierProvider = Provider.of<ImageClassifierProvider>(context, listen: false);
          
          // Show a snackbar to indicate processing has started
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Starting ML Kit image classification on ${imageFiles.length} images...'),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Process images
          print('DEBUG: About to call processImagesAndUpdateCategories with path: $workingPath');
          await classifierProvider.processImagesAndUpdateCategories(workingPath);
          print('DEBUG: Finished processing images from custom path');
      
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
        }
      }
    } catch (e) {
      print('DEBUG ERROR: Error using custom directory: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error with custom directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reclassifyAfterJsonUpdate(BuildContext context) async {
    try {
      // Show a dialog to confirm
      final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reclassify After JSON Update'),
          content: const Text(
            'This will reload the updated image_labelling_classes.json file and reclassify all images using the new category mappings. Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reclassify'),
            ),
          ],
        ),
      ) ?? false;
      
      if (confirm) {
        // Reset the checkpoint to force reprocessing
        await ImageClassifierService.resetCheckpoint();
        
        // Restart the image classifier to reload JSON
        final classifierProvider = Provider.of<ImageClassifierProvider>(context, listen: false);
        await classifierProvider.restartClassifier();
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON mappings reloaded. Classification will use updated categories on next scan.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('DEBUG ERROR: Failed to reclassify after JSON update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reclassifying after JSON update: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

