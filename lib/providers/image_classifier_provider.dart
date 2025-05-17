import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_classifier_service.dart';
import '../models/photo_item.dart';
import 'photo_provider.dart';

class ImageClassifierProvider extends ChangeNotifier {
  final ImageClassifierService _classifierService = ImageClassifierService();
  final PhotoProvider _photoProvider;
  
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  
  String? _error;
  String? get error => _error;
  
  // Progress tracking
  int _totalImages = 0;
  int _processedImages = 0;
  double get progress => _totalImages > 0 ? _processedImages / _totalImages : 0.0;
  
  // Directory for images to process
  String? _imagesPath;
  String? get imagesPath => _imagesPath;
  
  // Constructor
  ImageClassifierProvider(this._photoProvider) {
    // Initialize the ML Kit model when the provider is created
    _initializeMLKit();
    
    // Set up image directories
    _setupImagePaths();
  }
  
  // Initialize ML Kit model
  Future<void> _initializeMLKit() async {
    try {
      await initialize();
    } catch (e) {
      _error = 'Failed to initialize ML Kit: $e';
      print(_error);
    }
  }
  
  // Set up image paths and search for images in multiple locations
  Future<void> _setupImagePaths() async {
    try {
      // List of possible download folder locations to try
      final possiblePaths = [
        'raw:/storage/emulated/0/Download',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
        '/storage/self/primary/Download',
        '/storage/self/primary/Downloads',
      ];
      
      print('DEBUG: Searching for images in multiple locations...');
      
      // Try each path and check if it has images
      for (final path in possiblePaths) {
        print('DEBUG: Checking path: $path');
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            print('DEBUG: Directory exists: $path');
            
            // Check if there are any images in this directory
            final entities = await directory.list().toList();
            final imageFiles = entities.whereType<File>().where((file) {
              final extension = file.path.toLowerCase();
              return extension.endsWith('.jpg') || 
                     extension.endsWith('.jpeg') || 
                     extension.endsWith('.png') || 
                     extension.endsWith('.gif') ||
                     extension.endsWith('.bmp');
            }).toList();
            
            if (imageFiles.isNotEmpty) {
              print('DEBUG: Found ${imageFiles.length} images in $path');
              _imagesPath = path;
              
              // Print first few image paths for debugging
              for (int i = 0; i < imageFiles.length && i < 3; i++) {
                print('DEBUG: Sample image path: ${imageFiles[i].path}');
              }
              
              return;
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
      
      // If we reach here, we couldn't find images in any of the common locations
      // Let's try to use the application's documents directory as a fallback
      final appDocDir = await getApplicationDocumentsDirectory();
      _imagesPath = appDocDir.path;
      print('DEBUG: Using app documents folder as fallback: $_imagesPath');
      
      // Check if there are any files in the app documents directory
      try {
        final dir = Directory(_imagesPath!);
        final files = await dir.list().toList();
        print('DEBUG: App documents directory contains ${files.length} files/directories');
      } catch (e) {
        print('DEBUG: Error listing app documents directory: $e');
      }
    } catch (e) {
      print('DEBUG ERROR: Error setting up image paths: $e');
      _error = 'Failed to set up image paths: $e';
    }
  }
  
  // Initialize the classifier service
  Future<void> initialize() async {
    try {
      await _classifierService.initialize();
    } catch (e) {
      _error = 'Failed to initialize image classifier: $e';
      print(_error);
    }
  }
  
  // Classify a single image
  Future<String> classifyImage(String imagePath) async {
    try {
      print('DEBUG: classifyImage called for: $imagePath');
      
      // Verify file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        print('DEBUG ERROR: Image file does not exist: $imagePath');
        return 'Others';
      }
      
      // Verify file has content
      final fileSize = await file.length();
      if (fileSize == 0) {
        print('DEBUG ERROR: Image file is empty: $imagePath');
        return 'Others';
      }
      
      print('DEBUG: Calling ML Kit processImage for: $imagePath');
      final result = await _classifierService.processImage(imagePath);
      print('DEBUG: ML Kit result for $imagePath: $result');
      
      return result;
    } catch (e) {
      _error = 'Failed to classify image: $e';
      print('DEBUG ERROR: Failed to classify image $imagePath: $e');
      return 'Others';
    }
  }
  
  // Process all images in a folder and update the photo provider
  Future<void> processImagesAndUpdateCategories(String folderPath) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _error = null;
    _totalImages = 0;
    _processedImages = 0;
    notifyListeners();
    
    try {
      print('DEBUG: Starting to process images in folder: $folderPath');
      
      // Handle the 'raw:' prefix if present
      String actualFolderPath = folderPath;
      if (folderPath.startsWith('raw:')) {
        actualFolderPath = folderPath.substring(4); // Remove 'raw:' prefix for directory operations
        print('DEBUG: Using actual folder path without raw: prefix: $actualFolderPath');
      }
      
      // Get the list of image files
      final directory = Directory(actualFolderPath);
      
      if (!await directory.exists()) {
        print('DEBUG ERROR: Directory does not exist: $actualFolderPath');
        _error = 'Directory does not exist: $actualFolderPath';
        return;
      }
      
      print('DEBUG: Directory exists, getting file list...');
      final List<FileSystemEntity> entities = await directory.list().toList();
      print('DEBUG: Found ${entities.length} files/directories in $actualFolderPath');
      
      final List<File> imageFiles = entities
          .whereType<File>()
          .where((file) {
            final extension = file.path.toLowerCase();
            return extension.endsWith('.jpg') || 
                   extension.endsWith('.jpeg') || 
                   extension.endsWith('.png') || 
                   extension.endsWith('.bmp') || 
                   extension.endsWith('.gif');
          })
          .toList();
      
      _totalImages = imageFiles.length;
      print('DEBUG: Found $_totalImages image files to process');
      
      if (_totalImages == 0) {
        print('DEBUG: No image files found in directory: $actualFolderPath');
        _error = 'No image files found in directory';
        notifyListeners();
        return;
      }
      
      // Print the paths of the first few images for debugging
      for (int i = 0; i < _totalImages && i < 3; i++) {
        print('DEBUG: Image ${i+1} path: ${imageFiles[i].path}');
      }
      
      notifyListeners();
      
      // Get last processed timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastTimestamp = prefs.getDouble(ImageClassifierService.CHECKPOINT_KEY) ?? 0.0;
      double newLastTimestamp = lastTimestamp;
      print('DEBUG: Last processed timestamp: $lastTimestamp');
      
      // Check if there are any newer images that need processing
      bool hasNewerImages = false;
      for (final file in imageFiles) {
        final modTime = await file.lastModified();
        final modTimeMillis = modTime.millisecondsSinceEpoch.toDouble();
        if (modTimeMillis > lastTimestamp) {
          hasNewerImages = true;
          break;
        }
      }
      
      if (!hasNewerImages && lastTimestamp > 0) {
        print('DEBUG: No newer images found since last processing (timestamp: $lastTimestamp)');
        _error = 'No new images to process since last run';
        _isProcessing = false;
        notifyListeners();
        return;
      }
      
      // Make sure classifier is initialized
      try {
        await initialize();
        print('DEBUG: Classifier initialized before processing');
      } catch (e) {
        print('DEBUG ERROR: Failed to initialize classifier: $e');
      }
      
      // Process each image
      for (final file in imageFiles) {
        try {
          print('\nDEBUG: Processing image: ${file.path}');
          
          final modTime = await file.lastModified();
          final modTimeMillis = modTime.millisecondsSinceEpoch.toDouble();
          
          // Skip already processed files
          if (modTimeMillis <= lastTimestamp) {
            print('DEBUG: Skipping already processed file: ${file.path}');
            _processedImages++;
            notifyListeners();
            continue;
          }
          
          // Verify file exists and is readable
          if (!await file.exists()) {
            print('DEBUG ERROR: File does not exist: ${file.path}');
            continue;
          }
          
          final fileSize = await file.length();
          print('DEBUG: File size: $fileSize bytes');
          
          if (fileSize == 0) {
            print('DEBUG ERROR: File is empty: ${file.path}');
            continue;
          }
          
          // Process the image
          print('DEBUG: Calling classifyImage on ${file.path}');
          final category = await classifyImage(file.path);
          print('DEBUG: Classified ${file.path} as: $category');
          
          // Create a PhotoItem for this image if one doesn't exist
          final fileName = file.path.split('/').last;
          bool photoFound = false;
          
          // Find the corresponding photo in the provider
          final photos = _photoProvider.photos;
          for (final photo in photos) {
            if (photo.title == fileName) {
              // Add the photo to the appropriate category
              _photoProvider.addPhotoToCategory(photo.id, category);
              print('DEBUG: Added existing photo ${photo.id} to category: $category');
              photoFound = true;
              break;
            }
          }
          
          // If no photo was found for this image, create one
          if (!photoFound) {
            // Create a new photo and add it to the provider
            print('DEBUG: No existing photo found for $fileName. Creating new PhotoItem...');
            
            // Tell the photo provider to add this file as a new photo
            _photoProvider.addPhotoFromFile(file, category);
            print('DEBUG: Created new photo from file: ${file.path}');
          }
          
          // Update progress
          _processedImages++;
          
          // Update the most recent timestamp
          if (modTimeMillis > newLastTimestamp) {
            newLastTimestamp = modTimeMillis;
          }
          
          notifyListeners();
        } catch (e) {
          print('DEBUG ERROR: Failed to process individual image ${file.path}: $e');
        }
      }
      
      // Update checkpoint with latest timestamp
      if (newLastTimestamp > lastTimestamp) {
        await prefs.setDouble(ImageClassifierService.CHECKPOINT_KEY, newLastTimestamp);
        print('DEBUG: Updated last processed timestamp to: $newLastTimestamp');
      }
      
      print('DEBUG: Completed processing $_processedImages out of $_totalImages images');
      
    } catch (e) {
      _error = 'Failed to process images: $e';
      print('DEBUG ERROR: Failed to process images: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Process images in background
  Future<void> processImagesInBackground(String folderPath) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      final Map<String, List<String>> categorizedImages = 
          await ImageClassifierService.processImagesInBackground(folderPath);
      
      // Update the photo provider with the categorized images
      for (final entry in categorizedImages.entries) {
        final category = entry.key;
        final imagePaths = entry.value;
        
        for (final imagePath in imagePaths) {
          final fileName = imagePath.split('/').last;
          final photos = _photoProvider.photos;
          for (final photo in photos) {
            if (photo.title == fileName) {
              _photoProvider.addPhotoToCategory(photo.id, category);
              break;
            }
          }
        }
      }
      
    } catch (e) {
      _error = 'Failed to process images in background: $e';
      print(_error);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  // Restart the classifier to reload JSON mappings
  Future<void> restartClassifier() async {
    try {
      print('DEBUG: Restarting image classifier to reload JSON mappings');
      // Dispose the current service
      _classifierService.dispose();
      
      // Wait a moment to ensure resources are freed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Reinitialize the service
      await initialize();
      
      print('DEBUG: Image classifier successfully restarted');
      return;
    } catch (e) {
      print('DEBUG ERROR: Failed to restart classifier: $e');
      _error = 'Failed to restart classifier: $e';
      throw Exception('Failed to restart classifier: $e');
    }
  }
  
  // Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Reset the classifier and clear cached data
  Future<void> resetClassifier() async {
    try {
      print('DEBUG: Resetting image classifier');
      // Reset the service
      await ImageClassifierService.resetCheckpoint();
      
      // Restart the classifier
      await restartClassifier();
      
      print('DEBUG: Image classifier successfully reset');
    } catch (e) {
      print('DEBUG ERROR: Failed to reset classifier: $e');
      _error = 'Failed to reset classifier: $e';
      throw Exception('Failed to reset classifier: $e');
    }
  }
  
  // Dispose resources
  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }
}
