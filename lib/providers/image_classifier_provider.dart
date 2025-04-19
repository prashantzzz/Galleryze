import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  
  // Constructor
  ImageClassifierProvider(this._photoProvider);
  
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
      return await _classifierService.processImage(imagePath);
    } catch (e) {
      _error = 'Failed to classify image: $e';
      print(_error);
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
      // Get the list of image files
      final directory = Directory(folderPath);
      final List<FileSystemEntity> entities = await directory.list().toList();
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
      notifyListeners();
      
      // Get last processed timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastTimestamp = prefs.getDouble(ImageClassifierService.CHECKPOINT_KEY) ?? 0.0;
      double newLastTimestamp = lastTimestamp;
      
      // Process each image
      for (final file in imageFiles) {
        final modTime = await file.lastModified();
        final modTimeMillis = modTime.millisecondsSinceEpoch.toDouble();
        
        // Skip already processed files
        if (modTimeMillis <= lastTimestamp) {
          _processedImages++;
          notifyListeners();
          continue;
        }
        
        // Process the image
        final category = await classifyImage(file.path);
        
        // Find the corresponding photo in the provider
        final fileName = file.path.split('/').last;
        final photos = _photoProvider.photos;
        for (final photo in photos) {
          if (photo.title == fileName) {
            // Add the photo to the appropriate category
            _photoProvider.addPhotoToCategory(photo.id, category);
            break;
          }
        }
        
        // Update progress
        _processedImages++;
        
        // Update the most recent timestamp
        if (modTimeMillis > newLastTimestamp) {
          newLastTimestamp = modTimeMillis;
        }
        
        notifyListeners();
      }
      
      // Update checkpoint with latest timestamp
      if (newLastTimestamp > lastTimestamp) {
        await prefs.setDouble(ImageClassifierService.CHECKPOINT_KEY, newLastTimestamp);
      }
      
    } catch (e) {
      _error = 'Failed to process images: $e';
      print(_error);
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
  
  // Dispose resources
  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }
}
