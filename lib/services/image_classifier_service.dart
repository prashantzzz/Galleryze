import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ImageClassifierService {
  static const String CHECKPOINT_KEY = 'last_processed_timestamp';
  
  // Singleton instance
  static final ImageClassifierService _instance = ImageClassifierService._internal();
  factory ImageClassifierService() => _instance;
  ImageClassifierService._internal();
  
  // Available categories
  static const List<String> categories = ['Docs', 'People', 'Animal', 'Nature', 'Food', 'Others'];
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
      print('ImageClassifierService initialized successfully');
    } catch (e) {
      print('Error initializing ImageClassifierService: $e');
      rethrow;
    }
  }
  
  // Process a single image and return its category
  Future<String> processImage(String imagePath) async {
    if (!_isInitialized) await initialize();
    
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: $imagePath');
      }
      
      // For demo purposes, assign random categories
      // In a real application, you would implement actual image classification logic here
      final random = Random();
      final category = categories[random.nextInt(categories.length)];
      
      print('Assigned category: $category for $imagePath');
      return category;
    } catch (e) {
      print('Error processing image $imagePath: $e');
      return 'Others'; // Default category on error
    }
  }
  
  // Process a folder of images
  Future<Map<String, List<String>>> processFolder(String folderPath) async {
    if (!_isInitialized) await initialize();
    
    final Map<String, List<String>> categorizedImages = {
      'Docs': [],
      'People': [],
      'Animal': [],
      'Nature': [],
      'Food': [],
      'Others': []
    };
    
    try {
      final Directory directory = Directory(folderPath);
      final List<FileSystemEntity> entities = await directory.list().toList();
      
      for (final entity in entities) {
        if (entity is File) {
          final String ext = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(ext)) {
            final category = await processImage(entity.path);
            categorizedImages[category]?.add(entity.path);
          }
        }
      }
    } catch (e) {
      print('Error processing folder $folderPath: $e');
    }
    
    return categorizedImages;
  }
  
  // Static method for background processing
  static Future<Map<String, List<String>>> processImagesInBackground(String folderPath) async {
    final service = ImageClassifierService();
    await service.initialize();
    return await service.processFolder(folderPath);
  }
  
  // Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
