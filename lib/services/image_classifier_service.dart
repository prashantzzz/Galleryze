import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'dart:async';
import 'dart:math';

class ImageClassifierService {
  static const String CHECKPOINT_KEY = 'last_processed_timestamp';
  
  // Singleton instance
  static final ImageClassifierService _instance = ImageClassifierService._internal();
  factory ImageClassifierService() => _instance;
  ImageClassifierService._internal();
  
  // Available categories
  static const List<String> categories = ['Documents', 'People', 'Animals', 'Nature', 'Food', 'Others'];
  
  // ML Kit Image Labeler
  ImageLabeler? _imageLabeler;
  
  // Category mappings from image_labelling_classes.json
  Map<String, dynamic> _categoryMappings = {};
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('DEBUG: Starting ImageClassifierService initialization');
      
      // Initialize the ML Kit Image Labeler with default options
      final options = ImageLabelerOptions(confidenceThreshold: 0.7);
      _imageLabeler = ImageLabeler(options: options);
      
      // Load category mappings from asset
      print('DEBUG: Loading category mappings from asset');
      try {
        final String jsonString = await rootBundle.loadString('test/image_labelling_classes.json');
        print('DEBUG: Category mappings JSON loaded, size: ${jsonString.length}');
        _categoryMappings = jsonDecode(jsonString);
        print('DEBUG: Category mappings decoded, number of categories: ${_categoryMappings.keys.length}');
        print('DEBUG: Available categories: ${_categoryMappings.keys.join(', ')}');
      } catch (e) {
        print('DEBUG ERROR: Failed to load category mappings: $e');
        rethrow;
      }
      
      _isInitialized = true;
      print('DEBUG: ImageClassifierService initialized successfully');
    } catch (e) {
      print('DEBUG ERROR: Error initializing ImageClassifierService: $e');
      rethrow;
    }
  }
  
  // Find category for label
  String _findCategoryForLabel(String label) {
    // Print the input label for debugging
    final lowerLabel = label.toLowerCase();
    
    // Check each category for the label
    for (final category in _categoryMappings.keys) {
      final labels = _categoryMappings[category] as List<dynamic>;
      
      // Convert list items to lowercase for case-insensitive comparison
      final lowerCaseLabels = labels.map((item) => item.toString().toLowerCase()).toList();
      
      if (lowerCaseLabels.contains(lowerLabel)) {
        // Found an exact match
        final appCategory = _mapCategoryToAppCategory(category);
        return appCategory;
      }
    }
    
    // If no exact match found, check for partial matches
    for (final category in _categoryMappings.keys) {
      final labels = _categoryMappings[category] as List<dynamic>;
      
      for (final item in labels) {
        final itemStr = item.toString().toLowerCase();
        if (lowerLabel.contains(itemStr) || itemStr.contains(lowerLabel)) {
          // Found a partial match
          final appCategory = _mapCategoryToAppCategory(category);
          return appCategory;
        }
      }
    }
    
    return 'Others';
  }
  
  // Map JSON file categories to app categories
  String _mapCategoryToAppCategory(String jsonCategory) {
    if (jsonCategory == 'Document') return 'Documents';
    if (jsonCategory == 'People') return 'People';
    if (jsonCategory == 'Animal') return 'Animals';
    if (jsonCategory == 'Nature') return 'Nature';
    if (jsonCategory == 'Food') return 'Food';
    return 'Others';
  }
  
  // Process a single image and return its category
  Future<String> processImage(String imagePath) async {
    print('DEBUG: processImage called for: $imagePath');
    
    if (!_isInitialized) {
      print('DEBUG: Service not initialized, initializing now...');
      await initialize();
    }
    
    try {
      print('DEBUG: Validating image file: $imagePath');
      
      // Handle the 'raw:' prefix if present
      String actualPath = imagePath;
      if (imagePath.startsWith('raw:')) {
        actualPath = imagePath.substring(4); // Remove 'raw:' prefix
        print('DEBUG: Removed raw: prefix, using path: $actualPath');
      }
      
      final File imageFile = File(actualPath);
      if (!await imageFile.exists()) {
        print('DEBUG ERROR: Image file does not exist: $actualPath');
        throw Exception('Image file does not exist: $actualPath');
      }
      
      final fileSize = await imageFile.length();
      print('DEBUG: File size: $fileSize bytes');
      
      if (fileSize <= 0) {
        print('DEBUG ERROR: Image file is empty: $actualPath');
        throw Exception('Image file is empty: $actualPath');
      }
      
      // Create InputImage from file
      print('DEBUG: Creating InputImage from file path');
      final inputImage = InputImage.fromFilePath(actualPath);
      
      // Verify that imageLabeler is initialized
      if (_imageLabeler == null) {
        print('DEBUG ERROR: ImageLabeler is null, attempting to reinitialize');
        await initialize();
        if (_imageLabeler == null) {
          print('DEBUG ERROR: Failed to initialize ImageLabeler');
          throw Exception('ImageLabeler is null after initialization');
        }
      }
      
      // Process the image with ML Kit
      print('DEBUG: Calling ML Kit to process image');
      final labels = await _imageLabeler!.processImage(inputImage);
      print('DEBUG: ML Kit processing complete, found ${labels.length} labels');
      
      // Print detailed classification results
      final fileName = actualPath.split('/').last;
      print('\n==== ML Kit Classification Results for $fileName ====');
      
      if (labels.isEmpty) {
        print('DEBUG: No labels detected for this image');
      } else {
        // Sort by confidence (highest first)
        labels.sort((a, b) => b.confidence.compareTo(a.confidence));
        
        // Print top 5 results or all if less than 5
        final int resultsToShow = labels.length > 5 ? 5 : labels.length;
        
        for (int i = 0; i < resultsToShow; i++) {
          final label = labels[i];
          final confidence = (label.confidence * 100).toStringAsFixed(1);
          print(' ${i+1}. ${label.label} - $confidence% confidence');
          
          // Show which category this label maps to
          final category = _findCategoryForLabel(label.label);
          print('    → Mapped to category: $category');
        }
      }
      print('================================================\n');
      
      // Find the highest confidence label
      if (labels.isNotEmpty) {
        labels.sort((a, b) => b.confidence.compareTo(a.confidence));
        final topLabel = labels.first;
        print('DEBUG: Top label for $fileName: ${topLabel.label} (${(topLabel.confidence * 100).toStringAsFixed(1)}%)');
        
        // NEW LOGIC: Check the first 5 labels for a non-"Others" category
        final int labelsToCheck = labels.length > 5 ? 5 : labels.length;
        String finalCategory = 'Others';
        
        // First, specifically check for People category in top 5
        bool foundPeople = false;
        for (int i = 0; i < labelsToCheck; i++) {
          final currentLabel = labels[i];
          final currentCategory = _findCategoryForLabel(currentLabel.label);
          
          if (currentCategory == 'People') {
            finalCategory = 'People';
            foundPeople = true;
            print('DEBUG: Found People category from label #${i+1}: ${currentLabel.label}');
            break;
          }
        }
        
        // If People not found, then use existing logic for finding first non-Others
        if (!foundPeople) {
          for (int i = 0; i < labelsToCheck; i++) {
            final currentLabel = labels[i];
            final currentCategory = _findCategoryForLabel(currentLabel.label);
            
            // If we find a non-Others category, use it and break
            if (currentCategory != 'Others') {
              finalCategory = currentCategory;
              print('DEBUG: Using non-Others category from label #${i+1}: ${currentLabel.label} -> $finalCategory');
              break;
            }
          }
        }
        
        // If no non-Others category found in top 5, use the category of the top label
        if (finalCategory == 'Others') {
          finalCategory = _findCategoryForLabel(topLabel.label);
          print('DEBUG: No non-Others category found in top 5 labels, using top label category: $finalCategory');
        }
        
        print('DEBUG: Final category for $fileName: $finalCategory');
        return finalCategory;
      }
      
      print('DEBUG: No labels found, returning "Others"');
      return 'Others'; // Default category if no labels found
    } catch (e) {
      print('DEBUG ERROR: Error processing image $imagePath: $e');
      print('DEBUG ERROR: Error stack trace: ${StackTrace.current}');
      return 'Others'; // Default category on error
    }
  }
  
  /// Process all images in a folder and categorize them
  Future<Map<String, List<String>>> processFolder(String folderPath, {bool forceReprocess = false}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    print('Starting to process folder: $folderPath');
    final stopwatch = Stopwatch()..start();
    
    final Map<String, List<String>> categorizedImages = {
      'Documents': [],
      'People': [],
      'Animals': [],
      'Nature': [],
      'Food': [],
      'Others': [],
    };
    
    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        print('Error: Directory does not exist: $folderPath');
        return categorizedImages;
      }
      
      final List<FileSystemEntity> files = await directory.list().toList();
      print('Found ${files.length} files in directory');
      
      // Get last processed timestamp if not forcing reprocess
      double lastTimestamp = 0.0;
      if (!forceReprocess) {
        final prefs = await SharedPreferences.getInstance();
        lastTimestamp = prefs.getDouble(CHECKPOINT_KEY) ?? 0.0;
        print('Using last processed timestamp: $lastTimestamp');
        
        // Check if there are any newer images
        bool hasNewerImages = false;
        for (final file in files) {
          if (file is File) {
            final modTime = await file.lastModified();
            final modTimeMillis = modTime.millisecondsSinceEpoch.toDouble();
            if (modTimeMillis > lastTimestamp) {
              hasNewerImages = true;
              break;
            }
          }
        }
        
        if (!hasNewerImages && lastTimestamp > 0) {
          print('No newer images found since last processing (timestamp: $lastTimestamp)');
          return categorizedImages;
        }
      }
      
      int processedCount = 0;
      int successCount = 0;
      int errorCount = 0;
      double newLastTimestamp = lastTimestamp;
      
      for (final file in files) {
        if (file is File) {
          final String path = file.path;
          final String extension = path.split('.').last.toLowerCase();
          
          if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
            // Skip if already processed and not forcing reprocess
            if (!forceReprocess) {
              final modTime = await file.lastModified();
              final modTimeMillis = modTime.millisecondsSinceEpoch.toDouble();
              if (modTimeMillis <= lastTimestamp) {
                print('Skipping already processed file: $path');
                continue;
              }
              
              // Update the most recent timestamp
              if (modTimeMillis > newLastTimestamp) {
                newLastTimestamp = modTimeMillis;
              }
            }
            
            try {
              print('Processing image: $path');
              final category = await processImage(path);
              if (category != null) {
                categorizedImages[category]!.add(path);
                successCount++;
                print('Successfully categorized as: $category');
              } else {
                print('Image classified but no matching category found: $path');
                categorizedImages['Others']!.add(path);
              }
            } catch (e) {
              print('Error processing image $path: $e');
              categorizedImages['Others']!.add(path);
              errorCount++;
            }
            processedCount++;
            
            if (processedCount % 10 == 0) {
              print('Progress: Processed $processedCount files. Success: $successCount, Errors: $errorCount');
            }
          } else {
            print('Skipping non-image file: $path');
          }
        }
      }
      
      // Update timestamp if not forcing reprocess
      if (!forceReprocess && newLastTimestamp > lastTimestamp) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(CHECKPOINT_KEY, newLastTimestamp);
        print('Updated last processed timestamp to: $newLastTimestamp');
      }
      
      stopwatch.stop();
      print('Completed processing folder. Total files: ${files.length}, Processed: $processedCount, '
            'Success: $successCount, Errors: $errorCount, Time: ${stopwatch.elapsedMilliseconds}ms');
      
      // Print category statistics
      categorizedImages.forEach((category, images) {
        print('Category: $category, Count: ${images.length}');
      });
      
    } catch (e) {
      print('Error processing folder: $e');
    }
    
    return categorizedImages;
  }
  
  // Static method for background processing
  static Future<Map<String, List<String>>> processImagesInBackground(String folderPath, {bool forceReprocess = false}) async {
    final service = ImageClassifierService();
    await service.initialize();
    return await service.processFolder(folderPath, forceReprocess: forceReprocess);
  }
  
  // Reset the checkpoint timestamp to force reprocessing of all images
  static Future<void> resetCheckpoint() async {
    try {
      print('DEBUG: Resetting image classification checkpoint timestamp');
      final prefs = await SharedPreferences.getInstance();
      // Set to 0 rather than removing to ensure consistent behavior
      await prefs.setDouble(CHECKPOINT_KEY, 0.0);
      print('DEBUG: Checkpoint timestamp has been reset to 0');
    } catch (e) {
      print('DEBUG ERROR: Failed to reset checkpoint timestamp: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    _imageLabeler?.close();
    _isInitialized = false;
  }
}
